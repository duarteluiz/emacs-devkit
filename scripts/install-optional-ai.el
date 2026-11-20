;;; install-optional-ai.el --- Optional gptel install -*- lexical-binding: t; -*-
(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless (package-installed-p 'gptel)
  (package-refresh-contents)
  (package-install 'gptel))
(princ "gptel installed. Configure your provider and credentials separately.\n")
