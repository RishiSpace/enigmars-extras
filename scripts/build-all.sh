#!/usr/bin/env bash
# Build every package listed in packages.d/ and index repo/x86_64.
#
# Each program stays in its own git (e.g. ~/Git-Repos/enigmars-util).
# This repo only stores the resulting .pkg.tar.zst + pacman db.
#
# Add another program: drop packages.d/<name>.conf (see enigmars-utils.conf)
# then re-run this script.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd makepkg
need_cmd git

if [[ "$(id -u)" -eq 0 ]]; then
  die "makepkg will not run as root; run ./scripts/build-all.sh as your user"
fi

mkdir -p "$REPO_DIR"

mapfile -t confs < <(package_confs)
((${#confs[@]})) || die "no packages.d/*.conf files"

resolve_src() {
  local src="${1:-}" giturl="${2:-}" name="$3"
  if [[ -n "$src" && "$src" != /* ]]; then
    src="$REPO_ROOT/$src"
  fi
  if [[ -n "$src" && -d "$src" ]]; then
    (cd "$src" && pwd)
    return 0
  fi
  if [[ -n "$giturl" ]]; then
    local dest="$REPO_ROOT/work/$name"
    info "No local checkout at $src; cloning $giturl"
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    git clone --depth 1 "$giturl" "$dest"
    printf '%s\n' "$dest"
    return 0
  fi
  die "no source for $name (looked at SRC=$src; set GIT= to clone)"
}

build_one() {
  local conf="$1"
  local NAME="" SRC="" GIT="" PKGBUILD_DIR="packaging/arch" PKGBUILD="PKGBUILD.local"
  # shellcheck disable=SC1090
  source "$conf"
  [[ -n "$NAME" ]] || die "NAME missing in $conf"

  local src pbdir
  src="$(resolve_src "${SRC:-}" "${GIT:-}" "$NAME")"
  pbdir="$src/${PKGBUILD_DIR}"
  [[ -f "$pbdir/$PKGBUILD" ]] || die "missing $pbdir/$PKGBUILD"

  info "Building $NAME from $src ($PKGBUILD)"
  (
    cd "$pbdir"
    # --nodeps: extras only packages files; ISO/host already has runtime deps.
    makepkg -f --noconfirm --nodeps -p "$PKGBUILD"
  )

  shopt -s nullglob
  local pkgs=() p
  for p in "$pbdir"/"$NAME"-[0-9]*.pkg.tar.zst; do
    [[ "$(basename "$p")" == *-debug-* ]] && continue
    pkgs+=("$p")
  done
  shopt -u nullglob
  ((${#pkgs[@]})) || die "makepkg produced no $NAME-*.pkg.tar.zst in $pbdir"

  # Replace previous versions of this package only; leave the others.
  rm -f "$REPO_DIR"/"$NAME"-[0-9]*.pkg.tar.zst
  cp -a "${pkgs[@]}" "$REPO_DIR/"
  info "Staged ${pkgs[*]##*/}"
}

for conf in "${confs[@]}"; do
  build_one "$conf"
done

"$REPO_ROOT/scripts/publish-repo.sh" "$REPO_DIR"

info "Built packages:"
ls -lh "$REPO_DIR"/*.pkg.tar.zst
