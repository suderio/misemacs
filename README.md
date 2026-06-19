# mise-emacs

A [mise-en-place](https://mise.jdx.dev) plugin for managing [Emacs](https://www.gnu.org/software/emacs/) versions.

## Installation

```bash
mise plugin add emacs [https://github.com/](https://github.com/)<YOUR_GITHUB_USER>/mise-emacs
```

## Usage

```bash
# List available versions
mise ls-remote emacs

# Install a specific version
mise install emacs@29.4

# Set as default
mise use -g emacs@29.4
```

## Platform Architecture
- Windows: The plugin downloads official pre-compiled zip binaries. Currently, GNU only supports amd64/x86_64 architecture for Windows out of the box.

- Linux & macOS: The plugin downloads the source tarball and leverages your host environment to compile Emacs. This gracefully solves the problem of finding binaries that match your specific C-library (glibc vs musl) and processor architecture (AMD, ARM).

### Build Dependencies (Unix Systems)
Since this plugin compiles from source on non-Windows machines, ensure you have your distro's base compilation packages:

#### Arch Linux / CachyOS:
```bash
sudo pacman -S base-devel ncurses gnutls
```

#### Debian / Ubuntu:
```bash
sudo apt install build-essential libncurses-dev libgnutls28-dev
```

#### macOS:
```bash
xcode-select --install
```

