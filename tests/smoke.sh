#!/usr/bin/env bash
# Integration tests: fresh installation, idempotency and local-edit preservation.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"
"$ROOT/install.sh" --yes --skip-apt --skip-packages
manifest="$HOME/.local/share/emacs-ubuntu24-kit/managed.tsv"
[[ -s "$manifest" ]]
[[ -s "$HOME/.config/emacs/cpp-workflow.el" ]]
[[ -s "$HOME/.config/emacs/simple-ui.el" ]]
first="$(sha256sum "$manifest" | awk '{print $1}')"
"$ROOT/install.sh" --yes --update --skip-apt --skip-packages
second="$(sha256sum "$manifest" | awk '{print $1}')"
[[ "$first" == "$second" ]] || { echo 'Manifest changed during no-op update.' >&2; exit 1; }
printf '\n;; user-customized preference\n' >> "$HOME/.config/emacs/cpp-workflow.el"
modified="$(sha256sum "$HOME/.config/emacs/cpp-workflow.el" | awk '{print $1}')"
"$ROOT/install.sh" --yes --update --skip-apt --skip-packages
after="$(sha256sum "$HOME/.config/emacs/cpp-workflow.el" | awk '{print $1}')"
[[ "$modified" == "$after" ]] || { echo 'User changes were overwritten.' >&2; exit 1; }
"$ROOT/install.sh" --dry-run --update --skip-apt --skip-packages
echo '[OK] Fresh install, repeat update, local-change protection and dry-run passed.'
