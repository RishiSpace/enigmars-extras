#!/usr/bin/env bash
# Index every *.pkg.tar.zst in repo/x86_64 into enigmars-extras.db.
# GitHub Releases cannot serve repo-add's .db symlink, so this writes
# regular-file copies of .db / .files.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd repo-add

DEST="${1:-$REPO_DIR}"
mkdir -p "$DEST"

shopt -s nullglob
pkgs=()
for p in "$DEST"/*.pkg.tar.zst; do
  [[ "$(basename "$p")" == *-debug-* ]] && continue
  pkgs+=("$p")
done
shopt -u nullglob
((${#pkgs[@]})) || die "no packages in $DEST — run ./scripts/build-all.sh first"

info "Indexing ${#pkgs[@]} package(s) in $DEST"
(
  cd "$DEST"
  rm -f "${DB_NAME}.db" "${DB_NAME}.db.tar.gz" \
        "${DB_NAME}.files" "${DB_NAME}.files.tar.gz" \
        "${DB_NAME}.db.tar.gz.old" "${DB_NAME}.files.tar.gz.old"

  repo-add --new --remove "${DB_NAME}.db.tar.gz" "${pkgs[@]##*/}"

  for stem in "${DB_NAME}.db" "${DB_NAME}.files"; do
    if [[ -L "$stem" ]]; then
      target="$(readlink -f "$stem")"
      rm -f "$stem"
      cp -a "$target" "$stem"
    elif [[ -f "${stem}.tar.gz" && ! -f "$stem" ]]; then
      cp -a "${stem}.tar.gz" "$stem"
    fi
  done

  sha256sum ./*.pkg.tar.zst \
    "${DB_NAME}.db" "${DB_NAME}.db.tar.gz" \
    "${DB_NAME}.files" "${DB_NAME}.files.tar.gz" \
    > SHA256SUMS
)

for f in "${DB_NAME}.db" "${DB_NAME}.db.tar.gz" "${DB_NAME}.files" "${DB_NAME}.files.tar.gz"; do
  p="$DEST/$f"
  [[ -f "$p" ]] || die "missing $p"
  [[ ! -L "$p" ]] || die "$p is a symlink; GitHub Releases cannot serve it"
done

info "pacman repository ready"
echo
echo "[enigmars-extras]"
echo "SigLevel = Optional TrustAll"
echo "Server = https://github.com/${GITHUB_REPO}/releases/latest/download"
echo "# Server = file://${DEST}"
echo
echo "Upload with: ./scripts/upload-release-mirror.sh"
