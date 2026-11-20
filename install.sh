#!/usr/bin/env bash
# Idempotent Emacs DevKit installation with backups and managed-file checks.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.config/emacs"
STATE="$HOME/.local/share/emacs-ubuntu24-kit"
MANIFEST="$STATE/managed.tsv"
BACKUP_ROOT="$STATE/backups"
YES=0; SKIP_APT=0; SKIP_PACKAGES=0; UPDATE=0; DRY=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --skip-apt) SKIP_APT=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --update) UPDATE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help)
      echo 'Usage: ./install.sh [--yes] [--skip-apt] [--skip-packages] [--update] [--dry-run]'
      echo 'Installer backs up changed files and skips locally modified managed files during updates.'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fatal() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
trap 'warn "Interrupted near line $LINENO; any backup remains available."' ERR
[[ $(id -u) -ne 0 ]] || fatal 'Run as a regular user, not root.'
[[ -f /etc/os-release ]] || fatal 'Cannot identify operating system.'
. /etc/os-release
[[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 24.04 ]] ||
  warn "Designed for Ubuntu 24.04; detected ${PRETTY_NAME:-unknown}."
[[ -f "$ROOT/config/init.el" ]] || fatal 'Missing config/init.el. Clone the complete repository.'
if [[ $UPDATE -eq 1 && ! -f "$MANIFEST" ]]; then
  fatal 'No managed-file manifest found. Run ./install.sh interactively for the first installation.'
fi
hash() { sha256sum "$1" | awk '{print $1}'; }
entry() {
  case "$1" in
    .emacs)
      printf '%s\n' ';;; Emacs DevKit startup entry point.'
      printf '%s\n' '(load (expand-file-name "init.el" "~/.config/emacs/") nil '\''nomessage)'
      ;;
    *) cat "$ROOT/config/${1##*/}" ;;
  esac
}
names=(.emacs init.el development.el vscode-keys.el simple-ui.el cpp-workflow.el)
relative() {
  if [[ "$1" == .emacs ]]; then printf '.emacs'; else printf '.config/emacs/%s' "$1"; fi
}
# Preflight every source file before touching the user's setup.
for name in "${names[@]:1}"; do
  [[ -f "$ROOT/config/$name" ]] || fatal "Missing configuration: $name"
done
if command -v emacs >/dev/null; then
  for name in "${names[@]:1}"; do
    emacs --batch -Q --eval "(with-temp-buffer (insert-file-contents \"$ROOT/config/$name\") (check-parens))" >/dev/null 2>&1 ||
      fatal "Emacs Lisp syntax validation failed: $name"
  done
fi
# Compare with the hash installed during the previous run.
declare -A previous=()
if [[ -f "$MANIFEST" ]]; then
  while IFS=$'\t' read -r rel sha; do
    [[ -z "$rel" ]] || previous["$rel"]="$sha"
  done < "$MANIFEST"
fi
declare -a changes=()
declare -a protected=()
for name in "${names[@]}"; do
  rel="$(relative "$name")"
  dest="$HOME/$rel"
  expected="$(entry "$name" | sha256sum | awk '{print $1}')"
  if [[ -f "$dest" && "$(hash "$dest")" == "$expected" ]]; then
    info "Already current: $rel"
    continue
  fi
  if [[ $UPDATE -eq 1 ]]; then
    if [[ -z "${previous[$rel]:-}" ]]; then
      protected+=("$rel (not previously managed)")
      continue
    fi
    if [[ ! -f "$dest" ]] || [[ "$(hash "$dest")" != "${previous[$rel]}" ]]; then
      protected+=("$rel (locally modified or removed)")
      continue
    fi
  fi
  changes+=("$name")
done
for rel in "${protected[@]}"; do warn "Preserving $rel"; done
info "Files requiring installation: ${#changes[@]}"
if [[ $DRY -eq 1 ]]; then
  for name in "${changes[@]}"; do info "Would install: $(relative "$name")"; done
  info 'Dry run: no system or Emacs configuration changes made.'
  exit 0
fi
if [[ $YES -ne 1 ]]; then
  if [[ $UPDATE -eq 1 ]]; then
    read -r -p 'Apply safe managed-file updates? [y/N] ' reply
  else
    read -r -p 'Install Emacs DevKit and back up existing startup files? [y/N] ' reply
  fi
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi
if [[ $SKIP_APT -ne 1 ]]; then
  command -v sudo >/dev/null || fatal 'sudo is unavailable; rerun with --skip-apt.'
  sudo apt-get update || { sleep 3; sudo apt-get update || warn 'Could not refresh apt indexes.'; }
  required=(emacs-gtk clangd clang-format cmake ninja-build g++ make git ripgrep python3 python3-venv python3-pylsp)
  optional=(gdb clang-tidy python3-pip libvterm-dev libtool-bin libncurses-dev fonts-firacode fd-find curl)
  for pkg in "${required[@]}" "${optional[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
      continue
    fi
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg" ||
      warn "Package could not be installed: $pkg"
  done
fi
command -v emacs >/dev/null || fatal 'Emacs is missing. Install Emacs and retry.'
mkdir -p "$STATE" "$TARGET" "$BACKUP_ROOT"
if (( ${#changes[@]} > 0 )); then
  BACKUP="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p "$BACKUP"
  : > "$BACKUP/files.tsv"
  : > "$BACKUP/installed.tsv"
  if [[ -f "$MANIFEST" ]]; then cp -a "$MANIFEST" "$BACKUP/previous-managed.tsv"; fi
  for name in "${changes[@]}"; do
    rel="$(relative "$name")"
    dest="$HOME/$rel"
    if [[ -e "$dest" || -L "$dest" ]]; then
      mkdir -p "$BACKUP/original/$(dirname "$rel")"
      cp -a -- "$dest" "$BACKUP/original/$rel"
      printf 'present\t%s\n' "$rel" >> "$BACKUP/files.tsv"
    else
      printf 'absent\t%s\n' "$rel" >> "$BACKUP/files.tsv"
    fi
    mkdir -p "$(dirname "$dest")"
    temp="$(mktemp "$(dirname "$dest")/.devkit.XXXXXX")"
    entry "$name" > "$temp"
    chmod 0644 "$temp"
    mv -f -- "$temp" "$dest"
    digest="$(hash "$dest")"
    previous["$rel"]="$digest"
    printf '%s\t%s\n' "$rel" "$digest" >> "$BACKUP/installed.tsv"
    info "Installed: $rel"
  done
  printf '%s\n' "$BACKUP" > "$STATE/latest-backup"
  info "Recovery backup: $BACKUP"
fi
: > "$STATE/managed.tsv.tmp"
for rel in "${!previous[@]}"; do
  printf '%s\t%s\n' "$rel" "${previous[$rel]}"
done | sort > "$STATE/managed.tsv.tmp"
mv "$STATE/managed.tsv.tmp" "$MANIFEST"
if [[ $SKIP_PACKAGES -ne 1 ]]; then
  emacs --batch -Q -l "$ROOT/scripts/install-packages.el" ||
    warn 'Some Emacs packages could not be installed; review ./verify.sh.'
fi
"$ROOT/verify.sh" || warn 'Some verification checks need attention.'
info 'Setup completed. Restart Emacs to load the new configuration.'
echo 'Docker Engine and running containers were not modified.'
