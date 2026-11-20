#!/usr/bin/env bash
# Read-only host and editor checks.
set -u
failures=0
check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '[OK] %-15s %s\n' "$1" "$(command -v "$1")"
  else
    printf '[WARN] %-15s missing\n' "$1"
    failures=$((failures + 1))
  fi
}
for executable in emacs clangd clang-format g++ cmake ninja gdb python3 pylsp git; do
  check "$executable"
done
if command -v docker >/dev/null 2>&1; then
  echo '[INFO] Docker CLI detected (version inspection only).'
  docker --version || true
  docker compose version || true
else
  echo '[INFO] Docker CLI not detected; Docker UI is optional.'
fi
if command -v emacs >/dev/null 2>&1; then
  echo '[INFO] Testing Emacs startup in batch mode...'
  emacs --batch -Q -l "$HOME/.config/emacs/init.el" \
    --eval '(princ "[OK] Lisp startup loaded\n")' ||
    { echo '[WARN] Emacs startup failed.'; failures=$((failures + 1)); }
  echo '[INFO] Installed plugin status:'
  emacs --batch -Q \
    --eval '(progn (setq user-emacs-directory (expand-file-name "~/.config/emacs/")) (setq package-user-dir (expand-file-name "elpa" user-emacs-directory)) (require (quote package)) (package-initialize) (dolist (p (quote (corfu magit treemacs docker yasnippet editorconfig))) (princ (format "%s: %s\n" p (if (package-installed-p p) "OK" "MISSING")))))' || true
fi
if [[ $failures -ne 0 ]]; then
  echo "[WARN] $failures host check(s) need attention."
  exit 1
fi
echo '[OK] Core host checks passed. Verify GUI/LSP manually in Emacs.'
