# Emacs DevKit — Installation and User Guide

This guide explains how to install, use, troubleshoot, and roll back the Emacs DevKit on **Ubuntu 24.04 LTS**.

## 1. Prerequisites

You need a regular Ubuntu desktop user, internet access, sudo permissions, and a working terminal. The GUI editor requires a graphical desktop session. Emacs 29 or newer is recommended.

## 2. Installation

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/duarteluiz/emacs-devkit.git
cd emacs-devkit
./install.sh
./verify.sh
emacs
```

**Run the installer as your normal user. Do not use `sudo ./install.sh`.** The script asks before changing Emacs startup files. For noninteractive environments: `./install.sh --yes`. To skip host-package installation: `./install.sh --skip-apt`. To skip ELPA packages: `./install.sh --skip-packages`. The installer records SHA-256 checksums for its managed startup files, safely skips already-current files, and backs up files before changing them.

The installer backs up the startup files it replaces, installs missing editor dependencies and extensions, and runs a read-only verification. It never installs or modifies Docker Engine, Compose, containerd, or your running containers.

## 3. Basic editing

- `Ctrl+S`: save.
- `Ctrl+O`: open a file.
- `Ctrl+P`: find a project file.
- `Ctrl+Shift+P`: Emacs command prompt.
- `F8`: Treemacs file explorer.
- `F9`: a persistent bottom terminal (vterm, with shell fallback).
- `Ctrl+F5`: configure a CMake project in Debug mode.
- `F5`: build the current C++ program or CMake project.
- `F6`: select and run the compiled executable.
- `F7`: select and debug the executable with GDB.
- `F10`: Docker management UI.
- `M-x magit-status`: Git management.

CUA Mode provides familiar copy/cut/paste for selections; standard Emacs key prefixes remain available in other contexts. This is **inspired by** VS Code, not identical in every key sequence.

## 4. C++ sample project

```bash
mkdir -p ~/Projects/sensor-demo && cd ~/Projects/sensor-demo
cat > main.cpp <<'CPP'
#include <iostream>
#include <string>
#include <utility>

class MotionSensor {
public:
    explicit MotionSensor(std::string name) : name_(std::move(name)) {}
    void detect() const { std::cout << "Motion detected: " << name_ << '\n'; }
private:
    std::string name_;
};

int main() {
    MotionSensor sensor("Living Room PIR");
    sensor.detect();
}
CPP

cat > CMakeLists.txt <<'CMAKE'
cmake_minimum_required(VERSION 3.20)
project(SensorDemo LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(sensor_demo main.cpp)
CMAKE

cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
ln -sfn build/compile_commands.json compile_commands.json
./build/sensor_demo
emacs main.cpp
```

Eglot connects to clangd when opening C/C++ files. Corfu shows completion suggestions. The generated `compile_commands.json` tells clangd the real build flags. `F12` navigates to a definition, `F2` requests a rename, `Ctrl+C` then `F` formats C++ with clang-format, and `F5` builds the CMake project. Use `Ctrl+F5` to configure, `F6` to run, and `F7` to debug with GDB. See [C++ Workflow](CPP_WORKFLOW.md) for details.

## 5. Python sample

```bash
mkdir -p ~/Projects/python-sensors && cd ~/Projects/python-sensors
python3 -m venv .venv
source .venv/bin/activate
cat > sensor.py <<'PY'
class TemperatureSensor:
    def __init__(self, name: str):
        self.name = name

    def read_temperature(self) -> float:
        return 23.5

sensor = TemperatureSensor("Office")
print(sensor.read_temperature())
PY
python sensor.py
emacs sensor.py
```

Eglot uses `pylsp` for Python completion and diagnostics. Project virtual environments may need separate language-server configuration to resolve installed dependencies correctly.

## 6. Docker and Git

`F10` runs the `docker.el` interface. Docker itself must already be installed, running, and accessible to the current user. The installer never adds your user to the `docker` group because access to the Docker socket is highly privileged.

`M-x magit-status` opens Magit for Git diffs, commits, branches, and history. Use Magit carefully when working in a shared repository.

## 7. Terminal integration

First use of `M-x vterm` may ask to build `vterm-module`. Accept the prompt. The installer tries to provide the native dependencies, including `libvterm-dev`, CMake and a compiler. If native compilation is unavailable, use the built-in `M-x shell` as a fallback.

## 8. Optional AI

```bash
emacs --batch -Q -l scripts/install-optional-ai.el
```

This installs `gptel` but does not configure an AI provider, API key, billing or automatic login. Never commit secrets. GitHub Copilot for Emacs is a separate community integration: https://github.com/copilot-emacs/copilot.el .

## 9. Troubleshooting

**Package installation failed:** Run `./verify.sh`, inspect the failing dependency, and retry `./install.sh`. Optional package errors do not stop unrelated installations. The ELPA script retries repository metadata with a smaller mirror list.

**The editor cannot start:** Try `emacs -Q` to ignore custom startup configuration; then run `emacs --debug-init` to investigate. You can use `./rollback.sh` to restore the previous startup files.

**Python or C++ autocomplete is missing:** Verify `pylsp --version` or `clangd --version`. Use `M-x eglot` inside the source buffer and inspect `M-x eglot-events-buffer`. C++ projects should export `compile_commands.json`.

**Docker commands report a conflict:** Never install `docker.io` on top of Docker CE/`containerd.io`. The Emacs plugin only needs an existing Docker CLI. Check `docker --version`, `docker compose version`, and `docker ps` independently.

**The Emacs terminal fails:** Check CMake and `libvterm-dev`; retry `M-x vterm`, or use `M-x shell`.

**Keyboard shortcuts differ:** Some key combinations are captured by the Ubuntu desktop or the terminal; a major mode can also override global bindings. Use `M-x describe-key` to see the active command.

## 10. Rollback

```bash
./rollback.sh
```

This asks for confirmation and restores the most recent backup of the Emacs startup files replaced by the installer. It does not uninstall system packages, Emacs plugins, or touch project files and Docker data.

## 11. Validation and safe updates

```bash
./verify.sh
./update.sh --dry-run    # Check upstream and inspect local managed-file changes
./update.sh              # Fast-forward main and install safe changes
./update.sh --with-apt   # Also install missing host dependencies
```

The updater requires the official repository as its Git remote, a clean working tree, a nondiverged main branch and an existing Emacs DevKit managed-file manifest. It does not reset or force-pull Git history. It skips modified managed files and does not overwrite unmanaged local files. Identical files are not reinstalled. The first installation is done through `./install.sh`; on an older manually configured Emacs workstation, run the installer interactively once and examine its backup before updating.

`./install.sh --dry-run` previews configuration changes without installing packages. When updating, the script records a backup of changed startup files and records their SHA-256 checksums. `./rollback.sh` restores files only when they still match the deployed version, protecting modifications made later.

Each installation creates a new backup. Batch validation checks configuration loading but **does not prove GUI shortcuts, interactive LSP, vterm behavior, or Docker permissions work**. Verify those after opening Emacs.

### References

- [GNU Emacs manual](https://www.gnu.org/software/emacs/manual/)
- [Eglot manual](https://www.gnu.org/software/emacs/manual/html_mono/eglot.html)
- [clangd](https://clangd.llvm.org/)
- [Magit](https://magit.vc/)
- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [gptel](https://github.com/karthink/gptel)
