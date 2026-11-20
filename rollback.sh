#!/usr/bin/env bash
# Restore only the Emacs startup files replaced by the latest installation.
set -Eeuo pipefail
STATE="$HOME/.local/share/emacs-ubuntu24-kit/latest-backup"
[[ -f "$STATE" ]] || { echo 'No backup metadata found.' >&2; exit 1; }
BACKUP="$(cat "$STATE")"
[[ -f "$BACKUP/files.tsv" ]] || { echo 'Backup manifest missing.' >&2; exit 1; }
echo "Restore Emacs startup files from $BACKUP"
read -r -p 'Proceed? [y/N] ' reply
[[ "$reply" =~ ^[Yy]$ ]] || exit 0
while IFS=$'\t' read -r status rel; do
  case "$rel" in
    .emacs|.config/emacs/init.el|.config/emacs/vscode-keys.el|.config/emacs/development.el) ;;
    *) echo "Unexpected backup path: $rel" >&2; exit 1 ;;
  esac
  if [[ "$status" == present ]]; then
    mkdir -p "$(dirname "$HOME/$rel")"
    rm -f -- "$HOME/$rel"
    cp -a -- "$BACKUP/original/$rel" "$HOME/$rel"
    echo "Restored: $rel"
  elif [[ "$status" == absent ]]; then
    rm -f -- "$HOME/$rel"
    echo "Removed installer-created file: $rel"
  else
    echo "Invalid status: $status" >&2; exit 1
  fi
done < "$BACKUP/files.tsv"
echo 'Startup files restored. Packages and project files remain unchanged.'
