;;; install-packages.el --- ELPA/MELPA batch installer -*- lexical-binding: t; -*-
(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(defvar kit-packages
  '(doom-themes doom-modeline all-the-icons which-key vertico marginalia
    orderless consult corfu cape treemacs magit projectile rainbow-delimiters
    vterm docker dockerfile-mode yaml-mode markdown-mode yasnippet
    yasnippet-snippets editorconfig))
(let ((installed-count 0)
      (failed nil))
  (condition-case err
      (package-refresh-contents)
    (error
     (message "[WARN] Primary package refresh failed: %s"
              (error-message-string err))
     (setq package-archives
           '(("gnu" . "https://elpa.gnu.org/packages/")
             ("melpa" . "https://melpa.org/packages/")))
     (condition-case retry-error
         (package-refresh-contents)
       (error
        (message "[WARN] Fallback package refresh failed: %s"
                 (error-message-string retry-error))))))
  (dolist (pkg kit-packages)
    (condition-case err
        (progn
          (unless (package-installed-p pkg)
            (package-install pkg))
          (setq installed-count (1+ installed-count))
          (message "[OK] %s" pkg))
      (error
       (push (symbol-name pkg) failed)
       (message "[WARN] %s: %s" pkg (error-message-string err)))))
  (princ (format "Available: %d/%d packages\n"
                 installed-count (length kit-packages)))
  (when failed
    (princ (format "Packages needing attention: %s\n"
                   (mapconcat #'identity (nreverse failed) ", ")))
    (princ "Run the installer again after fixing network or repository issues.\n")))
