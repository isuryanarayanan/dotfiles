#!/bin/bash

set -e

# ──────────────────────────────────────────────
# dotfiles reinstall / sync script
#
# Checks the current state of the local system against
# the remote dotfiles repo and reconciles any differences.
#
# Usage:
#   ~/dotfiles/reinstall.sh                (run locally)
#   curl -fsSL https://raw.githubusercontent.com/isuryanarayanan/dotfiles/master/reinstall.sh | bash
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
    err "This step needs elevated privileges, but sudo is not available."
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

# ── Check packages ────────────────────────────

REQUIRED_CMDS_MACOS="git tmux nvim rg fd node cargo tmux-sessionizer starship fzf eza bat zoxide"
REQUIRED_CMDS_LINUX="git tmux nvim rg fd node starship fzf"

check_packages() {
  local os="$1"
  local missing=()
  local required

  if [ "$os" = "macos" ]; then
    required=$REQUIRED_CMDS_MACOS
  else
    required=$REQUIRED_CMDS_LINUX
  fi

  for cmd in $required; do
    if ! command_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    ok "All required commands available"
    return 0
  else
    warn "Missing commands: ${missing[*]}"
    return 1
  fi
}

install_missing_packages() {
  local os="$1"

  case "$os" in
    macos)
      if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -f /opt/homebrew/bin/brew ]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      fi

      local brew_packages=""
      command_exists git            || brew_packages="$brew_packages git"
      command_exists tmux           || brew_packages="$brew_packages tmux"
      command_exists nvim           || brew_packages="$brew_packages neovim"
      command_exists rg             || brew_packages="$brew_packages ripgrep"
      command_exists fd             || brew_packages="$brew_packages fd"
      command_exists node           || brew_packages="$brew_packages node"
      command_exists starship       || brew_packages="$brew_packages starship"
      command_exists fzf            || brew_packages="$brew_packages fzf"
      command_exists eza            || brew_packages="$brew_packages eza"
      command_exists bat            || brew_packages="$brew_packages bat"
      command_exists zoxide         || brew_packages="$brew_packages zoxide"

      if [ -n "$brew_packages" ]; then
        info "Installing missing Homebrew packages:$brew_packages"
        # shellcheck disable=SC2086
        brew install $brew_packages
      fi

      if ! command_exists cargo; then
        info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
      fi

      if ! command_exists tmux-sessionizer; then
        info "Installing tmux-sessionizer..."
        cargo install tmux-sessionizer
      fi
      ;;

    linux)
      local distro
      distro="$(detect_linux_distro)"
      case "$distro" in
        debian)
          run_privileged apt update
          run_privileged apt install -y git tmux neovim ripgrep fd-find nodejs npm
          ;;
        arch)
          run_privileged pacman -Sy --noconfirm git tmux neovim ripgrep fd nodejs npm
          ;;
        fedora)
          run_privileged dnf install -y git tmux neovim ripgrep fd-find nodejs npm
          ;;
        *)
          warn "Unknown distro. Please install missing packages manually."
          ;;
      esac
      ;;
  esac
}

# ── Repository sync ──────────────────────────

sync_dotfiles_repo() {
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles repo not found at $DOTFILES_DIR. Cloning fresh..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "Cloned dotfiles repo"
    return
  fi

  info "Checking dotfiles repo at $DOTFILES_DIR..."

  # Fetch latest from remote
  git -C "$DOTFILES_DIR" fetch origin

  # Check for local modifications
  local has_changes=false
  if ! git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null; then
    has_changes=true
  fi
  if ! git -C "$DOTFILES_DIR" diff --cached --quiet 2>/dev/null; then
    has_changes=true
  fi
  local untracked
  untracked="$(git -C "$DOTFILES_DIR" ls-files --others --exclude-standard)"
  if [ -n "$untracked" ]; then
    has_changes=true
  fi

  if [ "$has_changes" = true ]; then
    warn "Local modifications detected:"
    echo ""
    git -C "$DOTFILES_DIR" status --short
    echo ""

    # Show the diff for context
    info "Diff of modified files:"
    git -C "$DOTFILES_DIR" diff 2>/dev/null || true
    echo ""

    printf "\033[1;33mReset local changes to match remote? [y/N]:\033[0m "
    if [ -t 0 ]; then
      read -r answer
    else
      # Non-interactive (piped): default to yes
      answer="y"
      echo "y (non-interactive, defaulting to yes)"
    fi

    case "$answer" in
      [yY]|[yY][eE][sS])
        info "Resetting to origin/master..."
        git -C "$DOTFILES_DIR" reset --hard origin/master
        git -C "$DOTFILES_DIR" clean -fd
        ok "Local repo reset to remote state"
        ;;
      *)
        warn "Keeping local changes. Attempting merge..."
        git -C "$DOTFILES_DIR" stash
        if git -C "$DOTFILES_DIR" pull --ff-only; then
          ok "Pulled latest changes"
          if git -C "$DOTFILES_DIR" stash list | grep -q "stash@{0}"; then
            info "Re-applying stashed changes..."
            if git -C "$DOTFILES_DIR" stash pop; then
              ok "Stash applied successfully"
            else
              warn "Stash pop had conflicts. Resolve manually in $DOTFILES_DIR"
            fi
          fi
        else
          warn "Fast-forward pull failed. You may need to resolve manually."
          git -C "$DOTFILES_DIR" stash pop 2>/dev/null || true
        fi
        ;;
    esac
  else
    # No local changes, just pull
    local local_head remote_head
    local_head="$(git -C "$DOTFILES_DIR" rev-parse HEAD)"
    remote_head="$(git -C "$DOTFILES_DIR" rev-parse origin/master)"

    if [ "$local_head" = "$remote_head" ]; then
      ok "Dotfiles repo already up to date"
    else
      info "Pulling latest changes..."
      git -C "$DOTFILES_DIR" pull --ff-only
      ok "Dotfiles repo updated"
    fi
  fi
}

# ── Symlink verification ─────────────────────

check_symlink() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [ -L "$target" ]; then
    local current_link
    current_link="$(readlink "$target")"
    if [ "$current_link" = "$source" ]; then
      ok "$name symlink correct: $target -> $source"
      return 0
    else
      warn "$name symlink points to wrong location: $current_link (expected $source)"
      return 1
    fi
  elif [ -e "$target" ]; then
    warn "$name exists but is not a symlink: $target"
    return 1
  else
    warn "$name symlink missing: $target"
    return 1
  fi
}

fix_symlink() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [ ! -e "$source" ]; then
    err "Source does not exist: $source"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    local backup="${target}.bak"
    warn "Backing up existing $target to $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  ok "$name symlink created: $target -> $source"
}

verify_and_fix_symlinks() {
  local needs_fix=false

  info "Checking symlinks..."

  # Tmux
  if ! check_symlink "tmux" "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"; then
    needs_fix=true
    fix_symlink "tmux" "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  fi

  # Neovim
  if ! check_symlink "nvim" "$DOTFILES_DIR/nvim/nvim" "$HOME/.config/nvim"; then
    needs_fix=true
    fix_symlink "nvim" "$DOTFILES_DIR/nvim/nvim" "$HOME/.config/nvim"
  fi

  # Zsh
  if ! check_symlink "zshrc" "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"; then
    needs_fix=true
    fix_symlink "zshrc" "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  fi

  if ! check_symlink "zshenv" "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"; then
    needs_fix=true
    fix_symlink "zshenv" "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
  fi

  if ! check_symlink "zprofile" "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"; then
    needs_fix=true
    fix_symlink "zprofile" "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  fi

  if ! check_symlink "starship.toml" "$DOTFILES_DIR/zsh/starship/starship.toml" "$HOME/.config/starship.toml"; then
    needs_fix=true
    fix_symlink "starship.toml" "$DOTFILES_DIR/zsh/starship/starship.toml" "$HOME/.config/starship.toml"
  fi

  if [ "$needs_fix" = false ]; then
    ok "All symlinks correct"
  fi
}

# ── TPM / tmux plugins ───────────────────────

verify_tmux_plugins() {
  info "Checking tmux plugins..."

  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "TPM not installed. Installing..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "TPM installed"
  else
    # Update TPM itself
    git -C "$HOME/.tmux/plugins/tpm" pull --ff-only 2>/dev/null || true
    ok "TPM present"
  fi

  info "Installing/updating tmux plugins..."
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "Could not auto-install plugins. Start tmux and press Ctrl-b Shift-i."
  "$HOME/.tmux/plugins/tpm/bin/update_plugins" all 2>/dev/null || true
  ok "Tmux plugins up to date"
}

# ── Nvim theme ────────────────────────────────

verify_nvim_theme() {
  local theme_file="$DOTFILES_DIR/nvim/nvim/lua/plugins/theme.lua"
  local theme_default="$DOTFILES_DIR/nvim/nvim/lua/plugins/theme.lua.default"
  local omarchy_theme="$HOME/.config/omarchy/current/theme/neovim.lua"

  info "Checking nvim theme.lua..."

  # If theme.lua exists and is not a broken symlink, it's fine
  if [ -e "$theme_file" ]; then
    ok "theme.lua present"
    return
  fi

  # Remove broken symlink if present
  if [ -L "$theme_file" ]; then
    warn "theme.lua is a broken symlink, removing..."
    rm "$theme_file"
  fi

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

# ── Main ──────────────────────────────────────

main() {
  local os
  os="$(detect_os)"

  if [ "$os" = "macos" ] && is_root; then
    err "Do not run this script as root on macOS."
  fi

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       dotfiles reinstall         │"
  echo "  │       target: $os                │"
  echo "  └─────────────────────────────────┘"
  echo ""
  # 1. Check & install packages
  info "Step 1/6: Checking installed packages..."
  if ! check_packages "$os"; then
    install_missing_packages "$os"
    check_packages "$os" || warn "Some packages may still be missing"
  fi

  # 2. Sync dotfiles repo
  info "Step 2/6: Syncing dotfiles repository..."
  sync_dotfiles_repo

  # 3. Verify & fix symlinks
  info "Step 3/6: Verifying symlinks..."
  verify_and_fix_symlinks

  # 4. Verify tmux plugins
  info "Step 4/6: Verifying tmux plugins..."
  verify_tmux_plugins

  # 5. Verify nvim theme
  info "Step 5/6: Verifying nvim theme..."
  verify_nvim_theme

  # 6. Verify zsh setup
  info "Step 6/6: Verifying zsh setup..."
  local zsh_setup="$DOTFILES_DIR/zsh/setup_zsh.sh"
  if [ -f "$zsh_setup" ]; then
    bash "$zsh_setup"
  else
    warn "zsh/setup_zsh.sh not found, skipping zsh verification"
  fi

  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       Reinstall complete!        │"
  echo "  │                                  │"
  echo "  │  Your system is in sync with     │"
  echo "  │  the remote dotfiles repo.       │"
  echo "  │  Open a new terminal to apply    │"
  echo "  │  zsh changes.                    │"
  echo "  └─────────────────────────────────┘"
  echo ""
}

main "$@"
