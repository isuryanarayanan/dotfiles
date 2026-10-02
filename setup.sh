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
      nixos)                                   echo "nixos" ;;
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

version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

nvim_version_ok() {
  if ! command_exists nvim; then
    return 1
  fi

  local version
  version="$(nvim --version | head -n1 | sed -E 's/^NVIM v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  version_ge "$version" "0.10.0"
}

install_latest_neovim_linux() {
  if nvim_version_ok; then
    ok "Neovim version is compatible: $(nvim --version | head -n1)"
    return
  fi

  info "Installing latest Neovim to ~/.local/opt/nvim..."
  local tmpdir archive
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/nvim-linux-x86_64.tar.gz"

  if command_exists curl; then
    curl -fsSL -o "$archive" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  elif command_exists wget; then
    wget -qO "$archive" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  else
    err "Need curl or wget to install latest Neovim"
  fi

  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  rm -rf "$HOME/.local/opt/nvim"
  tar -xzf "$archive" -C "$tmpdir"
  mv "$tmpdir/nvim-linux-x86_64" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  export PATH="$HOME/.local/bin:$PATH"
  rm -rf "$tmpdir"

  ok "Installed $(nvim --version | head -n1)"
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
      run_privileged apt install -y git tmux neovim ripgrep fd-find nodejs npm zsh curl fzf
      ;;
    arch)
      info "Detected Arch-based distro"
      run_privileged pacman -Syu --needed --noconfirm git tmux neovim ripgrep fd nodejs npm zsh fzf
      ;;
    fedora)
      info "Detected Fedora/RHEL-based distro"
      run_privileged dnf install -y git tmux neovim ripgrep fd-find nodejs npm zsh fzf
      ;;
    *)
      warn "Unknown Linux distro. Please install manually: git, tmux, neovim, ripgrep, fd, nodejs"
      warn "Continuing with setup assuming packages are present..."
      ;;
  esac
  if [ "$distro" = "debian" ]; then
    install_latest_neovim_linux
  fi

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

# ── Ghostty setup ─────────────────────────────

setup_ghostty() {
  info "Setting up ghostty..."

  local ghostty_source="$DOTFILES_DIR/ghostty/config"
  local ghostty_target="$HOME/.config/ghostty/config"

  if [ ! -f "$ghostty_source" ]; then
    warn "ghostty/config not found in dotfiles, skipping ghostty setup"
    return
  fi

  mkdir -p "$HOME/.config/ghostty"

  if [ -L "$ghostty_target" ]; then
    local current_link
    current_link="$(readlink "$ghostty_target")"
    if [ "$current_link" = "$ghostty_source" ]; then
      ok "Ghostty symlink already correct"
    else
      warn "Existing symlink points to $current_link, replacing..."
      rm "$ghostty_target"
      ln -s "$ghostty_source" "$ghostty_target"
      ok "Symlinked $ghostty_target -> $ghostty_source"
    fi
  elif [ -f "$ghostty_target" ]; then
    warn "Existing ~/.config/ghostty/config found, backing up to ~/.config/ghostty/config.bak"
    mv "$ghostty_target" "${ghostty_target}.bak"
    ln -s "$ghostty_source" "$ghostty_target"
    ok "Symlinked $ghostty_target -> $ghostty_source"
  else
    ln -s "$ghostty_source" "$ghostty_target"
    ok "Symlinked $ghostty_target -> $ghostty_source"
  fi

  ok "Ghostty setup complete"
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

# ── Scripts setup ──────────────────────────────

setup_scripts() {
  info "Setting up custom scripts..."

  local scripts_setup="$DOTFILES_DIR/scripts/setup_scripts.sh"

  if [ ! -f "$scripts_setup" ]; then
    warn "scripts/setup_scripts.sh not found, skipping scripts setup"
    return
  fi

  bash "$scripts_setup"
  ok "Scripts setup complete"
}

# ── Pi setup ─────────────────────────────────

setup_pi() {
  info "Setting up Pi..."

  local pi_setup="$DOTFILES_DIR/pi/setup_pi.sh"

  if [ ! -f "$pi_setup" ]; then
    warn "pi/setup_pi.sh not found, skipping Pi setup"
    return
  fi

  bash "$pi_setup"
  ok "Pi setup complete"
}

# ── Main ──────────────────────────────────────

main() {
  local os
  os="$(detect_os)"

  if [ "$os" = "macos" ] && is_root; then
    err "Do not run this script as root on macOS (Homebrew forbids it). Run as your normal user without sudo."
  fi

  if [ "$os" = "linux" ] && [ "$(detect_linux_distro)" = "nixos" ]; then
    warn "NixOS uses the flake-based setup instead of this imperative installer."
    info "Clone the repo to $DOTFILES_DIR, then run:"
    info "sudo nixos-rebuild switch --flake $DOTFILES_DIR#nixos --extra-experimental-features 'nix-command flakes'"
    return
  fi

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       dotfiles setup             │"
  echo "  │       target: $os                │"
  echo "  └─────────────────────────────────┘"
  echo ""

  # 1. Install packages
  info "Step 1/8: Installing packages..."
  case "$os" in
    macos) install_packages_macos ;;
    linux) install_packages_linux ;;
  esac

  # 1.5 Install tmux-sessionizer
  info "Step 1.5/8: Installing tmux-sessionizer..."
  install_tmux_sessionizer

  # 2. Clone/update dotfiles repo
  info "Step 2/8: Setting up dotfiles repository..."
  setup_dotfiles_repo

  # 3. Tmux
  info "Step 3/8: Setting up tmux..."
  setup_tmux

  # 4. Neovim
  info "Step 4/8: Setting up neovim..."
  setup_nvim

  # 5. Zsh
  info "Step 5/8: Setting up zsh..."
  setup_zsh

  # 6. Ghostty
  info "Step 6/8: Setting up ghostty..."
  setup_ghostty

  # 7. Custom scripts
  info "Step 7/8: Setting up custom scripts..."
  setup_scripts

  # 8. Pi
  info "Step 8/8: Setting up Pi..."
  setup_pi

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       Setup complete!            │"
  echo "  │                                  │"
  echo "  │  Next steps:                     │"
  echo "  │  1. Open a new terminal          │"
  echo "  │  2. Open tmux                    │"
  echo "  │  3. Open nvim (plugins will      │"
  echo "  │     install on first launch)     │"
  echo "  │  4. Run pi and /login if needed  │"
  echo "  └─────────────────────────────────┘"
  echo ""
}

main "$@"
