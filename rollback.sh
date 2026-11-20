#!/usr/bin/env bash
# Restore only last changed Emacs startup files; never discard subsequent edits.
set -Eeuo pipefail
STATE="$HOME/.local/share/emacs-ubuntu24-kit"
MANIFEST="$STATE/managed.tsv"
[[ -f "$STATE/latest-backup" ]] || { echo 'No recovery backup is recorded.' >&2; exit 1; }
BACKUP="$(cat "$STATE/latest-backup")"
[[ "$BACKUP" == "$STATE/backups/"* && -f "$BACKUP/files.tsv" && -f "$BACKUP/installed.tsv" ]] ||
  { echo 'Invalid recovery backup metadata.' >&2; exit 1; }
echo "Recovery backup: $BACKUP"
read -r -p 'Restore the last Emacs DevKit configuration changes? [y/N] ' reply
[[ "$reply" =~ ^[Yy]$ ]] || exit 0
declare -A installed=()
while IFS=$'\t' read -r rel sha; do
  [[ -z "$rel" ]] || installed["$rel"]="$sha"
done < "$BACKUP/installed.tsv"
modified=0
while IFS=$'\t' read -r status rel; do
  case "$rel" in
    .emacs|.config/emacs/init.el|.config/emacs/vscode-keys.el|.config/emacs/development.el|.config/emacs/simple-ui.el|.config/emacs/cpp-workflow.el) ;;
    *) echo "Refusing unexpected path: $rel" >&2; exit 1 ;;
  esac
  target="$HOME/$rel"
  if [[ ! -f "$target" || "$(sha256sum "$target" | awk '{print $1}')" != "${installed[$rel]:-}" ]]; then
    echo "[WARN] Preserving user-modified or missing file: $rel"
    modified=1
    continue
  fi
  if [[ "$status" == present ]]; then
    [[ -e "$BACKUP/original/$rel" || -L "$BACKUP/original/$rel" ]] ||
      { echo "Original backup missing: $rel" >&2; exit 1; }
    rm -f -- "$target"
    cp -a -- "$BACKUP/original/$rel" "$target"
    echo "[OK] Restored: $rel"
  elif [[ "$status" == absent ]]; then
    rm -f -- "$target"
    echo "[OK] Removed installer-created file: $rel"
  else
    echo "Invalid backup entry: $status" >&2; exit 1
  fi
done < "$BACKUP/files.tsv"
if [[ $modified -eq 0 ]]; then
  if [[ -f "$BACKUP/previous-managed.tsv" ]]; then
    cp -a -- "$BACKUP/previous-managed.tsv" "$MANIFEST"
  else
    rm -f -- "$MANIFEST"
  fi
  echo '[OK] Managed-file state restored.'
else
  echo '[WARN] Partial rollback. Managed-file manifest retained for safety.'
fi
echo 'System packages, Emacs plugins, Git repository and Docker were not changed.'
