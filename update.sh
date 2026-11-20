#!/usr/bin/env bash
# Safe Emacs DevKit updater. Never discards local Git changes.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
YES=0; DRY=0; WITH_APT=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --dry-run) DRY=1 ;;
    --with-apt) WITH_APT=1 ;;
    -h|--help)
      printf '%s\n' 'Usage: ./update.sh [--yes] [--dry-run] [--with-apt]'
      printf '%s\n' 'Requires a clean main branch and preserves locally edited configuration files.'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[[ $(id -u) -ne 0 ]] || { echo 'Run as normal user.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Git is required.' >&2; exit 1; }
[[ "$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" == "$ROOT" ]] ||
  { echo 'Run from a cloned Git repository.' >&2; exit 1; }
[[ "$(git -C "$ROOT" branch --show-current)" == main ]] ||
  { echo 'Switch to the main branch before updating.' >&2; exit 1; }
[[ -z "$(git -C "$ROOT" status --porcelain)" ]] ||
  { echo 'Uncommitted/untracked files found. Commit, stash or move them first.' >&2; exit 1; }
origin="$(git -C "$ROOT" remote get-url origin)"
case "$origin" in
  https://github.com/duarteluiz/emacs-devkit|https://github.com/duarteluiz/emacs-devkit.git|git@github.com:duarteluiz/emacs-devkit.git) ;;
  *) echo "Unknown origin: $origin. Check the remote before proceeding." >&2; exit 1 ;;
esac
echo '[INFO] Checking upstream main for a fast-forward update.'
git -C "$ROOT" fetch origin main
current="$(git -C "$ROOT" rev-parse HEAD)"
upstream="$(git -C "$ROOT" rev-parse FETCH_HEAD)"
if ! git -C "$ROOT" merge-base --is-ancestor "$current" "$upstream"; then
  echo 'Local Git history diverges from origin/main; resolve manually.' >&2
  exit 1
fi
if [[ "$current" == "$upstream" ]]; then
  echo '[OK] Repository already up to date.'
else
  printf '[INFO] Update available: %.12s -> %.12s\n' "$current" "$upstream"
fi
if [[ $DRY -eq 1 ]]; then
  "$ROOT/install.sh" --update --dry-run --skip-apt --skip-packages
  echo '[OK] Dry run finished; no Emacs configuration was changed.'
  exit 0
fi
if [[ "$current" != "$upstream" ]]; then
  git -C "$ROOT" merge --ff-only "$upstream"
fi
options=(--update --skip-apt)
[[ $WITH_APT -eq 1 ]] && options=(--update)
[[ $YES -eq 1 ]] && options+=(--yes)
"$ROOT/install.sh" "${options[@]}"
echo '[OK] Update completed. Review warnings and restart Emacs.'
