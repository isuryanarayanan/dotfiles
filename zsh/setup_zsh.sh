#!/bin/bash

# ──────────────────────────────────────────────
# zsh/setup_zsh.sh
#
# Installs zsh productivity tools and symlinks the managed zsh config files
# (~/.zshrc, ~/.zshenv, ~/.zprofile, ~/.config/starship.toml) into the repo.
#
# Can be run standalone or called by the root setup.sh / reinstall.sh.
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ZSH_ZSHRC_SOURCE="$SCRIPT_DIR/.zshrc"
ZSH_ZSHENV_SOURCE="$SCRIPT_DIR/.zshenv"
ZSH_ZPROFILE_SOURCE="$SCRIPT_DIR/.zprofile"
STARSHIP_SOURCE="$SCRIPT_DIR/starship/starship.toml"

ZSH_ZSHRC_TARGET="$HOME/.zshrc"
ZSH_ZSHENV_TARGET="$HOME/.zshenv"
ZSH_ZPROFILE_TARGET="$HOME/.zprofile"
STARSHIP_TARGET="$HOME/.config/starship.toml"

# ── Helpers ───────────────────────────────────

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       err "Unsupported OS: $(uname -s)" ;;
  esac
}

# ── Symlink helper ────────────────────────────

# link_file <label> <source> <target>
#   Creates a symlink from <target> -> <source>.
#   Backs up any existing non-symlink file.
#   Updates the symlink if it already points elsewhere.
link_file() {
  local label="$1"
  local source="$2"
  local target="$3"

  if [ ! -e "$source" ]; then
    err "Source does not exist: $source"
  fi

  # Create parent directories if needed
  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    local current_link
    current_link="$(readlink "$target")"
    if [ "$current_link" = "$source" ]; then
      ok "$label symlink already correct"
      return
    else
      warn "$label symlink points to $current_link, replacing..."
      rm "$target"
    fi
  elif [ -e "$target" ]; then
    local backup="${target}.bak"
    warn "$label file exists at $target, backing up to $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  ok "Symlinked $target -> $source"
}

# ── Tool installation ─────────────────────────

install_brew_tools() {
  local os="$1"

  if [ "$os" != "macos" ]; then
    return
  fi

  if ! command_exists brew; then
    warn "Homebrew not found. Skipping Homebrew tool installation."
    return
  fi

  local tools_to_install=""

  command_exists starship || tools_to_install="$tools_to_install starship"
  command_exists fzf      || tools_to_install="$tools_to_install fzf"
  command_exists fd       || tools_to_install="$tools_to_install fd"
  command_exists eza      || tools_to_install="$tools_to_install eza"
  command_exists bat      || tools_to_install="$tools_to_install bat"
  command_exists zoxide   || tools_to_install="$tools_to_install zoxide"
  command_exists tldr     || tools_to_install="$tools_to_install tlrc"

  if [ -n "$tools_to_install" ]; then
    info "Installing zsh tools via Homebrew:$tools_to_install"
    # shellcheck disable=SC2086
    brew install $tools_to_install
    ok "Homebrew tools installed"
  else
    ok "All zsh tools already installed"
  fi
}

install_linux_tools() {
  local distro
  distro="$1"

  local missing_tools=""
  command_exists starship || missing_tools="$missing_tools starship"
  command_exists fzf      || missing_tools="$missing_tools fzf"
  command_exists fd       || missing_tools="$missing_tools fd-find(fd)"
  command_exists eza      || missing_tools="$missing_tools eza"
  command_exists bat      || missing_tools="$missing_tools bat"
  command_exists zoxide   || missing_tools="$missing_tools zoxide"

  if [ -z "$missing_tools" ]; then
    ok "All zsh tools already installed"
    return
  fi

  warn "The following tools need manual installation on Linux: $missing_tools"
  info "Installation instructions:"
  info "  starship: curl -sS https://starship.rs/install.sh | sh"
  info "  fzf:      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install"
  info "  zoxide:   curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
  case "$distro" in
    debian)
      info "  bat/fd/eza: sudo apt install bat fd-find && cargo install eza"
      ;;
    arch)
      info "  bat/fd/eza: sudo pacman -S bat fd eza"
      ;;
    fedora)
      info "  bat/fd:     sudo dnf install bat fd-find && cargo install eza"
      ;;
  esac
}

install_tools() {
  local os
  os="$(detect_os)"

  info "Installing zsh productivity tools..."

  case "$os" in
    macos)
      install_brew_tools "$os"
      ;;
    linux)
      local distro
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
          ubuntu|debian|pop|linuxmint|elementary) distro="debian" ;;
          arch|manjaro|endeavouros)               distro="arch" ;;
          fedora|rhel|centos|rocky|alma)          distro="fedora" ;;
          *)                                      distro="unknown" ;;
        esac
      else
        distro="unknown"
      fi
      install_linux_tools "$distro"
      ;;
  esac
}

# ── fzf key bindings ──────────────────────────

setup_fzf() {
  if ! command_exists fzf; then
    warn "fzf not installed, skipping fzf key binding setup"
    return
  fi

  # fzf >= 0.48 ships --zsh flag; older versions use the install script
  if fzf --zsh >/dev/null 2>&1; then
    ok "fzf --zsh supported (key bindings will be sourced in .zshrc)"
  elif [ -f "$HOME/.fzf.zsh" ]; then
    ok "fzf key bindings already installed at ~/.fzf.zsh"
  else
    info "Installing fzf shell extensions..."
    if [ -f "$(brew --prefix 2>/dev/null)/opt/fzf/install" ]; then
      "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish 2>/dev/null || true
    elif [ -f "$HOME/.fzf/install" ]; then
      "$HOME/.fzf/install" --all --no-bash --no-fish 2>/dev/null || true
    else
      warn "Could not find fzf install script. Key bindings may not work. Run: $(brew --prefix)/opt/fzf/install"
    fi
    ok "fzf key bindings installed"
  fi
}

# ── Symlinks ──────────────────────────────────

setup_symlinks() {
  info "Setting up zsh config symlinks..."

  link_file "zshrc"          "$ZSH_ZSHRC_SOURCE"    "$ZSH_ZSHRC_TARGET"
  link_file "zshenv"         "$ZSH_ZSHENV_SOURCE"   "$ZSH_ZSHENV_TARGET"
  link_file "zprofile"       "$ZSH_ZPROFILE_SOURCE" "$ZSH_ZPROFILE_TARGET"
  link_file "starship.toml"  "$STARSHIP_SOURCE"      "$STARSHIP_TARGET"

  ok "Zsh config symlinks done"
}

# ── Main ──────────────────────────────────────

main() {
  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       zsh setup                  │"
  echo "  └─────────────────────────────────┘"
  echo ""

  # 1. Install tools
  info "Step 1/3: Installing tools..."
  install_tools

  # 2. Set up fzf key bindings
  info "Step 2/3: Setting up fzf..."
  setup_fzf

  # 3. Symlink config files
  info "Step 3/3: Symlinking config files..."
  setup_symlinks

  echo ""
  ok "Zsh setup complete!"
  info "Open a new terminal or run: source ~/.zshrc"
  echo ""
}

main "$@"
