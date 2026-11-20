#!/usr/bin/env bash
# Reproducible Emacs setup for Ubuntu 24.04.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.config/emacs"
BACKUP_ROOT="$HOME/.local/share/emacs-ubuntu24-kit/backups"
YES=0; SKIP_APT=0; SKIP_PACKAGES=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --skip-apt) SKIP_APT=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -h|--help) echo "Usage: ./install.sh [--yes] [--skip-apt] [--skip-packages]"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fatal() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
trap 'warn "Setup failed near line $LINENO. Existing backups are preserved."' ERR
[[ $(id -u) -ne 0 ]] || fatal 'Run as your desktop user, not as root.'
[[ -f /etc/os-release ]] || fatal 'Cannot identify operating system.'
. /etc/os-release
if [[ "${ID:-}" != ubuntu || "${VERSION_ID:-}" != 24.04 ]]; then
  warn "Designed for Ubuntu 24.04; detected ${PRETTY_NAME:-unknown}."
  if [[ $YES -ne 1 ]]; then
    read -r -p 'Continue anyway? [y/N] ' reply
    [[ "$reply" =~ ^[Yy]$ ]] || exit 1
  fi
fi
[[ -f "$ROOT/config/init.el" ]] || fatal 'Missing config/init.el; clone the entire repository.'
if [[ $YES -ne 1 ]]; then
  echo 'This will back up and replace Emacs startup files. Docker Engine will not be changed.'
  read -r -p 'Proceed? [y/N] ' reply
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi

if [[ $SKIP_APT -ne 1 ]]; then
  command -v sudo >/dev/null || fatal 'sudo is required for apt; use --skip-apt if already configured.'
  info 'Updating Ubuntu package indexes (retry once on failure).'
  sudo apt-get update || { sleep 3; sudo apt-get update || warn 'apt index unavailable; continuing with cached metadata.'; }
  required=(emacs-gtk clangd clang-format cmake ninja-build g++ make git ripgrep python3 python3-venv python3-pylsp)
  optional=(gdb clang-tidy python3-pip libvterm-dev libtool-bin libncurses-dev fonts-firacode fd-find curl)
  for package in "${required[@]}" "${optional[@]}"; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
      continue
    fi
    info "Installing dependency: $package"
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$package" ||
      warn "Dependency unavailable: $package (check ./verify.sh after setup)."
  done
fi
command -v emacs >/dev/null || fatal 'Emacs not found; install Emacs or rerun without --skip-apt.'

STAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP="$BACKUP_ROOT/$STAMP"
mkdir -p "$BACKUP" "$TARGET" "$BACKUP_ROOT"
files=(".emacs" ".config/emacs/init.el" ".config/emacs/vscode-keys.el" ".config/emacs/development.el")
: > "$BACKUP/files.tsv"
for rel in "${files[@]}"; do
  if [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]]; then
    mkdir -p "$BACKUP/original/$(dirname "$rel")"
    cp -a -- "$HOME/$rel" "$BACKUP/original/$rel"
    printf 'present\t%s\n' "$rel" >> "$BACKUP/files.tsv"
  else
    printf 'absent\t%s\n' "$rel" >> "$BACKUP/files.tsv"
  fi
done
# This explicit entry point avoids precedence from an existing ~/.emacs file.
rm -f -- "$HOME/.emacs"
cat > "$HOME/.emacs" <<'LISP'
;;; Emacs DevKit startup entry point.
(load (expand-file-name "init.el" "~/.config/emacs/") nil 'nomessage)
LISP
for name in init.el vscode-keys.el development.el; do
  rm -f -- "$TARGET/$name"
  cp -- "$ROOT/config/$name" "$TARGET/$name"
done
mkdir -p "$HOME/.local/share/emacs-ubuntu24-kit"
printf '%s\n' "$BACKUP" > "$HOME/.local/share/emacs-ubuntu24-kit/latest-backup"
info "Configuration installed; backup saved at: $BACKUP"

if [[ $SKIP_PACKAGES -ne 1 ]]; then
  info 'Installing Emacs packages in batch mode.'
  emacs --batch -Q -l "$ROOT/scripts/install-packages.el" ||
    warn 'Emacs package installation reported a problem; check ./verify.sh.'
fi
info 'Checking installation.'
"$ROOT/verify.sh" || warn 'Some capabilities are missing. See the user guide.'
echo 'Setup complete. Run: emacs'
echo "Rollback available via: $ROOT/rollback.sh"
echo 'Docker Engine and existing containers were not modified.'
