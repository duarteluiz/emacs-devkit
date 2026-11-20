;;; install-packages.el --- Noninteractive ELPA/MELPA package installer -*- lexical-binding: t; -*-
(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(setq package-archive-priorities '(("gnu" . 20) ("nongnu" . 15) ("melpa" . 10)))
(package-initialize)
(defvar kit-packages
  '(doom-themes doom-modeline all-the-icons which-key
    vertico marginalia orderless consult corfu cape
    treemacs magit projectile rainbow-delimiters vterm
    docker dockerfile-mode yaml-mode markdown-mode
    yasnippet yasnippet-snippets editorconfig))
(let ((success 0) (failures nil))
  (condition-case err
      (package-refresh-contents)
    (error
     (message "[WARN] Primary refresh failed: %s" (error-message-string err))
     (setq package-archives
           '(("gnu" . "https://elpa.gnu.org/packages/")
             ("melpa" . "https://melpa.org/packages/")))
     (condition-case retry
         (package-refresh-contents)
       (error (message "[WARN] Fallback refresh failed: %s"
                       (error-message-string retry))))))
  (dolist (pkg kit-packages)
    (if (package-installed-p pkg)
        (progn
          (setq success (1+ success))
          (message "[OK] %s already installed" pkg))
      (condition-case err
          (progn
            (package-install pkg)
            (setq success (1+ success))
            (message "[OK] %s installed" pkg))
        (error
         (push (symbol-name pkg) failures)
         (message "[WARN] %s: %s" pkg (error-message-string err))))))
  (princ (format "\nInstalled/available: %d/%d\n" success (length kit-packages)))
  (when failures
    (princ (format "Unavailable packages: %s\n" (mapconcat #'identity (nreverse failures) ", ")))
    (princ "Re-run this script after resolving network or package issues.\n"))))
