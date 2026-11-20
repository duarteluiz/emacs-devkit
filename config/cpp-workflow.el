;;; cpp-workflow.el --- C++ build, run and debug -*- lexical-binding: t; -*-
(require 'compile)
(require 'gud)
(defvar kit/cpp-last-executable nil "Previously chosen executable.")
(defun kit/cpp-root ()
  "Find the closest CMake root or source folder."
  (file-name-as-directory
   (or (locate-dominating-file default-directory "CMakeLists.txt")
       (and buffer-file-name (file-name-directory buffer-file-name))
       default-directory)))
(defun kit/cpp-build-directory ()
  "Return the current project's build directory."
  (expand-file-name "build" (kit/cpp-root)))
(defun kit/cpp-cmake-project-p ()
  "Check for CMakeLists.txt at the project root."
  (file-exists-p (expand-file-name "CMakeLists.txt" (kit/cpp-root))))
(defun kit/cpp-configure-command ()
  "Prepare the CMake Debug configuration command."
  (let ((root (kit/cpp-root)) (dir (kit/cpp-build-directory)))
    (concat "cmake -S " (shell-quote-argument root)
            " -B " (shell-quote-argument dir)
            (if (file-exists-p (expand-file-name "CMakeCache.txt" dir))
                ""
              (if (executable-find "ninja") " -G Ninja" " -G \"Unix Makefiles\""))
            " -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")))
(defun kit/cpp-configure ()
  "Configure a CMake project in Debug mode."
  (interactive)
  (unless (kit/cpp-cmake-project-p) (user-error "No CMakeLists.txt found"))
  (unless (executable-find "cmake") (user-error "CMake not found"))
  (let ((default-directory (kit/cpp-root)))
    (compile (kit/cpp-configure-command))))
(defun kit/cpp-build ()
  "Build CMake or compile the current standalone C++ file."
  (interactive)
  (save-some-buffers t)
  (let ((default-directory (kit/cpp-root)))
    (if (kit/cpp-cmake-project-p)
        (let ((dir (kit/cpp-build-directory)))
          (unless (executable-find "cmake") (user-error "CMake not found"))
          (compile
           (concat (unless (file-exists-p (expand-file-name "CMakeCache.txt" dir))
                     (concat (kit/cpp-configure-command) " && "))
                   "cmake --build " (shell-quote-argument dir) " --parallel 2")))
      (unless (and buffer-file-name
                   (member (file-name-extension buffer-file-name) '("cpp" "cc" "cxx")))
        (user-error "Open a standalone .cpp, .cc or .cxx source file"))
      (unless (executable-find "g++") (user-error "g++ not found"))
      (let ((output (expand-file-name
                     (concat "build/" (file-name-base buffer-file-name)) default-directory)))
        (make-directory (file-name-directory output) t)
        (setq kit/cpp-last-executable output)
        (compile (format "g++ -std=c++20 -Wall -Wextra -g -O0 %s -o %s"
                         (shell-quote-argument buffer-file-name)
                         (shell-quote-argument output)))))))
(defun kit/cpp-select-executable ()
  "Select an executable to run or debug."
  (let* ((previous (and kit/cpp-last-executable
                        (file-exists-p kit/cpp-last-executable)
                        kit/cpp-last-executable))
         (selection
          (read-file-name "Executable: "
                          (if previous (file-name-directory previous)
                            (kit/cpp-build-directory))
                          previous t)))
    (unless (and (file-regular-p selection) (file-executable-p selection))
      (user-error "File is not executable: %s" selection))
    (setq kit/cpp-last-executable selection)
    selection))
(defun kit/cpp-run ()
  "Run the selected program; use F9 for interactive stdin."
  (interactive)
  (let ((default-directory (kit/cpp-root))
        (program (kit/cpp-select-executable)))
    (compile (shell-quote-argument program))))
(defun kit/cpp-debug ()
  "Debug a program with graphical GDB."
  (interactive)
  (unless (executable-find "gdb") (user-error "GDB not found"))
  (gdb (concat "gdb -i=mi " (shell-quote-argument (kit/cpp-select-executable)))))
(defun kit/cpp-terminal ()
  "Open or focus a terminal in a bottom-side window."
  (interactive)
  (let ((buffer (get-buffer "*DevKit Terminal*")))
    (unless buffer
      (setq buffer
            (condition-case err
                (save-window-excursion
                  (vterm "*DevKit Terminal*")
                  (current-buffer))
              (error
               (message "vterm unavailable: %s; using shell"
                        (error-message-string err))
               (save-window-excursion
                 (shell "*DevKit Terminal*")
                 (current-buffer))))))
    (let ((window (get-buffer-window buffer)))
      (select-window
       (if (window-live-p window) window
         (display-buffer-in-side-window
          buffer '((side . bottom) (slot . 0) (window-height . 0.30))))))))
(setq gdb-many-windows t gdb-show-main t)
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*" (display-buffer-in-side-window)
               (side . bottom) (slot . 1) (window-height . 0.28)))
(global-set-key (kbd "<f5>") #'kit/cpp-build)
(global-set-key (kbd "<f6>") #'kit/cpp-run)
(global-set-key (kbd "<f7>") #'kit/cpp-debug)
(global-set-key (kbd "<f9>") #'kit/cpp-terminal)
(global-set-key (kbd "C-<f5>") #'kit/cpp-configure)
(provide 'cpp-workflow)
