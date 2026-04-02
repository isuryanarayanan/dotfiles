#!/bin/bash

set -e

# ──────────────────────────────────────────────
# dotfiles setup script
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/isuryanarayanan/dotfiles/master/setup.sh | bash
# ──────────────────────────────────────────────

DOTFILES_REPO="https://github.com/isuryanarayanan/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# ── Helpers ───────────────────────────────────

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

is_root() {
  [ "${EUID:-$(id -u)}" -eq 0 ]
}

run_privileged() {
  if is_root; then
    "$@"
  elif command_exists sudo; then
    sudo "$@"
  else
    err "This step needs elevated privileges, but sudo is not available. Re-run as root or install sudo."
  fi
}

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       err "Unsupported OS: $(uname -s)" ;;
  esac
}

detect_linux_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|pop|linuxmint|elementary) echo "debian" ;;
      arch|manjaro|endeavouros)               echo "arch" ;;
      fedora|rhel|centos|rocky|alma)          echo "fedora" ;;
      *)                                      echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

# ── Package installation ─────────────────────

install_packages_macos() {
  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for the rest of this script
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  ok "Homebrew available"

  info "Installing packages via Homebrew..."
  brew install git tmux neovim ripgrep fd node starship fzf fd eza bat zoxide tlrc
  ok "Packages installed"
}

install_tmux_sessionizer() {
  if command_exists tmux-sessionizer; then
    ok "tmux-sessionizer already installed"
    return
  fi

  info "Installing tmux-sessionizer..."

  if ! command_exists cargo; then
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    . "$HOME/.cargo/env"
  fi

  cargo install tmux-sessionizer
  ok "tmux-sessionizer installed"
}

install_packages_linux() {
  local distro
  distro="$(detect_linux_distro)"

  case "$distro" in
    debian)
      info "Detected Debian/Ubuntu-based distro"
      run_privileged apt update
      run_privileged apt install -y git tmux neovim ripgrep fd-find nodejs npm
      ;;
    arch)
      info "Detected Arch-based distro"
      run_privileged pacman -Sy --noconfirm git tmux neovim ripgrep fd nodejs npm
      ;;
    fedora)
      info "Detected Fedora/RHEL-based distro"
      run_privileged dnf install -y git tmux neovim ripgrep fd-find nodejs npm
      ;;
    *)
      warn "Unknown Linux distro. Please install manually: git, tmux, neovim, ripgrep, fd, nodejs"
      warn "Continuing with setup assuming packages are present..."
      ;;
  esac
  ok "Packages installed"
}

# ── Clone dotfiles ────────────────────────────

setup_dotfiles_repo() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles repo already exists at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Pull failed, continuing with existing state"
  else
    info "Cloning dotfiles to $DOTFILES_DIR..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  ok "Dotfiles repo ready at $DOTFILES_DIR"
}

# ── Tmux setup ────────────────────────────────

setup_tmux() {
  info "Setting up tmux..."

  local tmux_source="$DOTFILES_DIR/tmux/.tmux.conf"
  local tmux_target="$HOME/.tmux.conf"

  # Symlink config
  if [ -L "$tmux_target" ]; then
    local current_link
    current_link="$(readlink "$tmux_target")"
    if [ "$current_link" = "$tmux_source" ]; then
      ok "Tmux symlink already correct"
    else
      warn "Existing symlink points to $current_link, replacing..."
      rm "$tmux_target"
      ln -s "$tmux_source" "$tmux_target"
      ok "Symlinked $tmux_target -> $tmux_source"
    fi
  elif [ -f "$tmux_target" ]; then
    warn "Existing ~/.tmux.conf found, backing up to ~/.tmux.conf.bak"
    mv "$tmux_target" "${tmux_target}.bak"
    ln -s "$tmux_source" "$tmux_target"
    ok "Symlinked $tmux_target -> $tmux_source"
  else
    ln -s "$tmux_source" "$tmux_target"
    ok "Symlinked $tmux_target -> $tmux_source"
  fi

  # Install TPM
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    ok "TPM already installed"
  else
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "TPM installed"
  fi

  # Install plugins
  info "Installing tmux plugins..."
  tmux start-server \; source-file "$HOME/.tmux.conf" 2>/dev/null || true
  tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/" 2>/dev/null || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "Could not auto-install plugins. Start tmux and press Ctrl-b Shift-i to install."

  ok "Tmux setup complete"
}

# ── Neovim setup ──────────────────────────────

setup_nvim() {
  info "Setting up neovim..."

  local nvim_source="$DOTFILES_DIR/nvim/nvim"
  local nvim_target="$HOME/.config/nvim"

  mkdir -p "$HOME/.config"

  if [ -L "$nvim_target" ]; then
    local current_link
    current_link="$(readlink "$nvim_target")"
    if [ "$current_link" = "$nvim_source" ]; then
      ok "Neovim symlink already correct"
      return
    else
      warn "Existing symlink points to $current_link, replacing..."
      rm "$nvim_target"
    fi
  elif [ -d "$nvim_target" ]; then
    warn "Existing ~/.config/nvim found, backing up to ~/.config/nvim.bak"
    mv "$nvim_target" "${nvim_target}.bak"
  elif [ -e "$nvim_target" ]; then
    warn "Existing ~/.config/nvim is not a directory, backing up to ~/.config/nvim.bak"
    mv "$nvim_target" "${nvim_target}.bak"
  fi

  ln -s "$nvim_source" "$nvim_target"
  ok "Symlinked $nvim_target -> $nvim_source"

  # Set up theme.lua (machine-specific, not tracked by git)
  setup_nvim_theme

  info "Launch nvim to complete plugin installation (plugins install automatically on first start)"
  ok "Neovim setup complete"
}

setup_nvim_theme() {
  local theme_file="$DOTFILES_DIR/nvim/nvim/lua/plugins/theme.lua"
  local theme_default="$DOTFILES_DIR/nvim/nvim/lua/plugins/theme.lua.default"
  local omarchy_theme="$HOME/.config/omarchy/current/theme/neovim.lua"

  # If theme.lua already exists and is not a broken symlink, leave it alone
  if [ -e "$theme_file" ]; then
    ok "theme.lua already present"
    return
  fi

  # Remove broken symlink if present
  [ -L "$theme_file" ] && rm "$theme_file"

  if [ -f "$omarchy_theme" ]; then
    info "Omarchy detected, symlinking theme to $omarchy_theme"
    ln -s "$omarchy_theme" "$theme_file"
    ok "theme.lua -> $omarchy_theme"
  elif [ -f "$theme_default" ]; then
    info "Using default theme (tokyonight)"
    cp "$theme_default" "$theme_file"
    ok "theme.lua created from default"
  else
    warn "No theme.lua.default found, skipping theme setup"
  fi
}

# ── Zsh setup ─────────────────────────────────

setup_zsh() {
  info "Setting up zsh..."

  local zsh_setup="$DOTFILES_DIR/zsh/setup_zsh.sh"

  if [ ! -f "$zsh_setup" ]; then
    warn "zsh/setup_zsh.sh not found, skipping zsh setup"
    return
  fi

  bash "$zsh_setup"
  ok "Zsh setup complete"
}

# ── Main ──────────────────────────────────────

main() {
  local os
  os="$(detect_os)"

  if [ "$os" = "macos" ] && is_root; then
    err "Do not run this script as root on macOS (Homebrew forbids it). Run as your normal user without sudo."
  fi

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       dotfiles setup             │"
  echo "  │       target: $os                │"
  echo "  └─────────────────────────────────┘"
  echo ""

  # 1. Install packages
  info "Step 1/5: Installing packages..."
  case "$os" in
    macos) install_packages_macos ;;
    linux) install_packages_linux ;;
  esac

  # 1.5 Install tmux-sessionizer
  info "Step 1.5/5: Installing tmux-sessionizer..."
  install_tmux_sessionizer

  # 2. Clone/update dotfiles repo
  info "Step 2/5: Setting up dotfiles repository..."
  setup_dotfiles_repo

  # 3. Tmux
  info "Step 3/5: Setting up tmux..."
  setup_tmux

  # 4. Neovim
  info "Step 4/5: Setting up neovim..."
  setup_nvim

  # 5. Zsh
  info "Step 5/5: Setting up zsh..."
  setup_zsh

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       Setup complete!            │"
  echo "  │                                  │"
  echo "  │  Next steps:                     │"
  echo "  │  1. Open a new terminal          │"
  echo "  │  2. Open tmux                    │"
  echo "  │  3. Open nvim (plugins will      │"
  echo "  │     install on first launch)     │"
  echo "  └─────────────────────────────────┘"
  echo ""
}

main "$@"
