# Shared helpers for enigmars-extras.
# shellcheck shell=bash

if [[ -n "${_ENIGMARS_EXTRAS_LIB_LOADED:-}" ]]; then
  return 0
fi
_ENIGMARS_EXTRAS_LIB_LOADED=1

set -euo pipefail

repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$here"
}

REPO_ROOT="$(repo_root)"
REPO_DIR="${ENIGMARS_EXTRAS_REPO_DIR:-$REPO_ROOT/repo/x86_64}"
PACKAGES_D="$REPO_ROOT/packages.d"
GITHUB_REPO="${ENIGMARS_EXTRAS_GITHUB:-RishiSpace/enigmars-extras}"
DB_NAME="enigmars-extras"

die() {
  printf '==> ERROR: %s\n' "$*" >&2
  exit 1
}

info() {
  # stderr so command substitutions (resolve_src, etc.) only capture paths
  printf '==> %s\n' "$*" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

package_confs() {
  local f
  shopt -s nullglob
  for f in "$PACKAGES_D"/*.conf; do
    printf '%s\n' "$f"
  done
  shopt -u nullglob
}
