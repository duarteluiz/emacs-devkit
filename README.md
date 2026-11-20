# Emacs DevKit

[![Validate](https://github.com/duarteluiz/emacs-devkit/actions/workflows/validate.yml/badge.svg)](https://github.com/duarteluiz/emacs-devkit/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**A reproducible, terminal-first Emacs development setup for Ubuntu 24.04 LTS.**

Emacs DevKit configures GNU Emacs for **C/C++, Python, Docker, Git, and modern editing**, with LSP-powered code completion, a dark theme, a file explorer, an integrated terminal, and VS Code-inspired keyboard shortcuts.

It is designed for a second laptop, a fresh Ubuntu installation, or a repeatable developer workstation setup.

## Features

| Category | Stack | Capabilities |
| --- | --- | --- |
| C/C++ | clangd, Eglot, Corfu, CMake, Ninja, GDB | Completion, diagnostics, code navigation, formatting and builds |
| Python | pylsp, Eglot | Completion and diagnostics |
| Docker | docker.el, dockerfile-mode, yaml-mode | View containers; edit Dockerfile and Compose files |
| Git | Magit | Status, staging, commits, branches and history |
| Editing | Treemacs, Vertico, Consult, Doom themes, yasnippet | Explorer, search, snippets and a modern look |
| Terminal | vterm / built-in shell | Shell access without leaving Emacs |
| Keyboard | CUA Mode and custom mappings | Familiar copy/paste/save/search shortcuts |
| Optional AI | gptel | AI chat with separate provider credentials |

## Quick start

**Requirements:** Ubuntu 24.04 LTS, internet connectivity, and sudo access.

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/duarteluiz/emacs-devkit.git
cd emacs-devkit
./install.sh
./verify.sh
emacs
```

The installer asks for confirmation before replacing Emacs startup files. **Run it as a regular user, not with sudo.** It uses sudo only for required Ubuntu packages.

### Installer options

```bash
./install.sh --help
./install.sh --yes             # Skip confirmation
./install.sh --skip-apt        # Use existing Ubuntu packages
./install.sh --skip-packages   # Use existing Emacs packages
./verify.sh                    # Read-only verification
./rollback.sh                  # Restore last Emacs startup-file backup
```

## Safety and existing Docker installations

The installer **does not install or modify Docker Engine, Docker Compose, or containerd**, and never starts, stops, removes, or reconfigures containers. This avoids conflicts between Ubuntu's `docker.io` and the official Docker CE/`containerd.io` packages.

Changed Emacs startup files are saved under `~/.local/share/emacs-ubuntu24-kit/backups/`. To undo those startup-file changes, run `./rollback.sh`. Rollback does not uninstall APT/ELPA packages.

Optional package installation failures are reported without aborting every other plugin. The verification script reports missing capabilities. No API keys or account tokens are stored in this repository.

## Documentation

- [User guide: installation, C++, Python, Docker, troubleshooting](docs/USER_GUIDE.md)
- [Keyboard shortcuts](docs/KEYBOARD_SHORTCUTS.md)
- [License](LICENSE)

## Repository structure

```text
emacs-devkit/
├── .github/workflows/validate.yml
├── config/
│   ├── init.el
│   ├── development.el
│   └── vscode-keys.el
├── docs/
│   ├── USER_GUIDE.md
│   └── KEYBOARD_SHORTCUTS.md
├── scripts/
│   ├── install-packages.el
│   └── install-optional-ai.el
├── install.sh
├── verify.sh
├── rollback.sh
├── LICENSE
└── README.md
```

## Optional AI

Run `emacs --batch -Q -l scripts/install-optional-ai.el` to install `gptel`; then configure an AI provider yourself. API usage may be billed separately. GitHub Copilot is not bundled or logged in automatically.

## Development and contribution

Validate shell and Emacs Lisp syntax with the included GitHub Actions workflow. Issues and pull requests are welcome. Include your Ubuntu/Emacs versions and reproducible steps; never attach credentials or sensitive project files.

## License

MIT — see [LICENSE](LICENSE).
