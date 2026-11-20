# Emacs DevKit — Keyboard Shortcuts

The profile uses CUA Mode and custom global bindings to approximate common VS Code shortcuts on a graphical Ubuntu desktop.

| Action | Shortcut | Notes |
| --- | --- | --- |
| Copy selection | Ctrl+C | CUA Mode; without a selection, Emacs prefixes may apply |
| Paste | Ctrl+V | CUA Mode |
| Cut selection | Ctrl+X | CUA Mode |
| Save | Ctrl+S | Save current buffer |
| Save as | Ctrl+Shift+S | `write-file` |
| Open file | Ctrl+O | `find-file` |
| Select all | Ctrl+A | Select whole buffer |
| Find text | Ctrl+F | Incremental search |
| Find project file | Ctrl+P | `project-find-file` |
| Command palette | Ctrl+Shift+P | `execute-extended-command` |
| Redo | Ctrl+Shift+Z | `undo-redo` |
| Replace text | Ctrl+Shift+H | `query-replace` |
| Toggle comment | Ctrl+/ | Current line or selected region |
| Go to definition | F12 | Works with Eglot/xref |
| Rename code symbol | F2 | Requires active Eglot server |
| Go back | Alt+Left | xref history |
| Open project explorer | F8 | Treemacs |
| Open integrated terminal | F9 | vterm |
| Docker management | F10 | docker.el |
| Open Git status | Alt+X, then `magit-status` | Magit |
| Compile | F5 | **Not** the debugger shortcut |
| Format C/C++ | Ctrl+C then F | `clang-format` |
| Quit/cancel Emacs command | Ctrl+G | Preserved intentionally |
| Emacs help | Ctrl+H | Preserved intentionally |

## Important limitations

- These are **VS Code-inspired**, not complete VS Code keymap emulation.
- `Ctrl+Shift+T` opens vterm here rather than restoring a closed tab.
- Ubuntu desktop shortcuts and terminal emulators may intercept some combinations.
- Emacs editing modes and the vterm buffer may override global key mappings.
- Use `M-x describe-key` followed by the key combination to inspect what currently runs.
