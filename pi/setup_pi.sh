#!/bin/bash

# ──────────────────────────────────────────────
# pi/setup_pi.sh
#
# Installs the Pi coding agent and symlinks the managed Pi settings file
# (~/.pi/agent/settings.json) into the repo.
#
# Can be run standalone or called by the root setup.sh / reinstall.sh.
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PI_SETTINGS_SOURCE="$SCRIPT_DIR/settings.json"
PI_SETTINGS_TARGET="$HOME/.pi/agent/settings.json"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_INSTALL_VERSION="v0.40.3"
REQUIRED_NODE_VERSION="22.19.0"
NODE_INSTALL_VERSION="--lts"

# ── Helpers ───────────────────────────────────

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Symlink helper ────────────────────────────

link_file() {
  local label="$1"
  local source="$2"
  local target="$3"

  if [ ! -e "$source" ]; then
    err "Source does not exist: $source"
  fi

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

# ── Node / nvm installation ───────────────────

version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

node_version_ok() {
  if ! command_exists node; then
    return 1
  fi

  local version
  version="$(node -p 'process.versions.node' 2>/dev/null || true)"
  [ -n "$version" ] && version_ge "$version" "$REQUIRED_NODE_VERSION"
}

install_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    ok "nvm already installed at $NVM_DIR"
    return
  fi

  info "Installing nvm to $NVM_DIR..."
  export NVM_DIR
  mkdir -p "$NVM_DIR"

  if command_exists curl; then
    PROFILE=/dev/null curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALL_VERSION/install.sh" | PROFILE=/dev/null bash
  elif command_exists wget; then
    PROFILE=/dev/null wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALL_VERSION/install.sh" | PROFILE=/dev/null bash
  else
    err "Need curl or wget to install nvm"
  fi

  [ -s "$NVM_DIR/nvm.sh" ] || err "nvm installation failed"
  ok "nvm installed"
}

source_nvm() {
  export NVM_DIR
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    err "nvm.sh not found at $NVM_DIR/nvm.sh"
  fi

  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
}

setup_node() {
  install_nvm
  source_nvm

  if node_version_ok && command_exists npm; then
    ok "Node is compatible: $(node --version)"
  else
    info "Installing latest Node.js LTS via nvm..."
    nvm install "$NODE_INSTALL_VERSION"
    nvm use "$NODE_INSTALL_VERSION" >/dev/null
    nvm alias default "$NODE_INSTALL_VERSION" >/dev/null
    hash -r
    ok "Latest Node.js LTS installed and set as default: $(node --version)"
  fi

  node_version_ok || err "Node.js $REQUIRED_NODE_VERSION or newer is required for Pi"
  command_exists npm || err "npm is required for Pi"
  ok "Using Node $(node --version) and npm $(npm --version)"
}

# ── Pi installation ───────────────────────────

install_pi() {
  setup_node

  if command_exists pi; then
    ok "Pi already installed: $(pi --version 2>/dev/null || printf 'version unknown')"
    return
  fi

  info "Installing Pi via npm..."
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent || err "Pi npm install failed"
  hash -r

  command_exists pi || err "Pi installation failed"
  ok "Pi installed: $(pi --version 2>/dev/null || printf 'version unknown')"
}

setup_settings() {
  link_file "pi settings" "$PI_SETTINGS_SOURCE" "$PI_SETTINGS_TARGET"
}

# ── Main ──────────────────────────────────────

main() {
  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       pi setup                  │"
  echo "  └─────────────────────────────────┘"
  echo ""

  # 1. Install Pi
  info "Step 1/2: Installing Pi..."
  install_pi

  # 2. Symlink settings
  info "Step 2/2: Symlinking Pi settings..."
  setup_settings

  echo ""
  ok "Pi setup complete!"
  info "Run 'pi' and use /login to authenticate your preferred provider if needed."
  echo ""
}

main "$@"
