#!/usr/bin/env bash
# Upload repo/x86_64 onto the Latest GitHub Release (pacman Server).
# Requires: gh (authenticated)
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd gh

TAG="${1:-}"
DEST="${2:-$REPO_DIR}"

if [[ -z "$TAG" ]]; then
  TAG="$(gh release list --repo "$GITHUB_REPO" --limit 20 \
    --json tagName,isLatest --jq '.[] | select(.isLatest==true) | .tagName' || true)"
fi
if [[ -z "$TAG" ]]; then
  TAG="repo"
  info "No Latest release; creating $TAG"
  gh release create "$TAG" --repo "$GITHUB_REPO" --title "enigmars-extras" \
    --notes "Rolling pacman repository. Pacman uses Latest, not git tags."
fi

[[ -d "$DEST" ]] || die "repo directory missing: $DEST"
[[ -f "$DEST/${DB_NAME}.db" ]] || die "run ./scripts/build-all.sh first ($DEST/${DB_NAME}.db missing)"
[[ ! -L "$DEST/${DB_NAME}.db" ]] || die "${DB_NAME}.db must be a regular file, not a symlink"

shopt -s nullglob
assets=(
  "$DEST/${DB_NAME}.db"
  "$DEST/${DB_NAME}.db.tar.gz"
  "$DEST/${DB_NAME}.files"
  "$DEST/${DB_NAME}.files.tar.gz"
  "$DEST/SHA256SUMS"
)
# Bookkeeping for CI polling: lets scheduled runs skip rebuilds when
# upstream package repos have not moved. Optional; ignored if missing.
if [[ -f "$DEST/UPSTREAM_SHAS" ]]; then
  assets+=("$DEST/UPSTREAM_SHAS")
fi
for p in "$DEST"/*.pkg.tar.zst; do
  [[ "$(basename "$p")" == *-debug-* ]] && continue
  assets+=("$p")
done
shopt -u nullglob

info "Uploading ${#assets[@]} assets to $GITHUB_REPO $TAG"
gh release upload "$TAG" --clobber --repo "$GITHUB_REPO" "${assets[@]}"

info "Mirror URL:"
echo "  https://github.com/${GITHUB_REPO}/releases/latest/download/${DB_NAME}.db"
