;;; development.el --- Language tools and developer integrations -*- lexical-binding: t; -*-
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("pylsp"))))
(add-hook 'python-mode-hook #'eglot-ensure)
(when (fboundp 'python-ts-mode)
  (add-hook 'python-ts-mode-hook #'eglot-ensure))
(when (require 'yasnippet nil t)
  (yas-global-mode 1))
(when (require 'editorconfig nil t)
  (editorconfig-mode 1))
(autoload 'docker "docker" "Open the Docker management interface." t)
(global-set-key (kbd "<f10>") #'docker)
(global-auto-revert-mode 1)
;; AI providers are opt-in; no credentials are stored in this public project.
