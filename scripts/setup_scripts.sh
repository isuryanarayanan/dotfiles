#!/bin/bash

# ──────────────────────────────────────────────
# scripts/setup_scripts.sh
#
# Symlinks custom scripts from this repo into ~/.local/bin
# so they are available on PATH.
#
# Can be run standalone or called by the root setup.sh / reinstall.sh.
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# ── Helpers ───────────────────────────────────

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Symlink helper ────────────────────────────

link_script() {
  local source="$1"
  local name="$2"
  local target="$BIN_DIR/$name"

  if [ ! -f "$source" ]; then
    err "Source does not exist: $source"
  fi

  # Ensure source is executable
  chmod +x "$source"

  if [ -L "$target" ]; then
    local current_link
    current_link="$(readlink "$target")"
    if [ "$current_link" = "$source" ]; then
      ok "$name symlink already correct"
      return
    else
      warn "$name symlink points to $current_link, replacing..."
      rm "$target"
    fi
  elif [ -e "$target" ]; then
    local backup="${target}.bak"
    warn "$name exists at $target, backing up to $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  ok "Symlinked $target -> $source"
}

# ── Main ──────────────────────────────────────

main() {
  echo ""
  echo "  ┌─────────────────────────────────┐"
  echo "  │       scripts setup              │"
  echo "  └─────────────────────────────────┘"
  echo ""

  # 1. Ensure ~/.local/bin exists
  mkdir -p "$BIN_DIR"

  # 2. Symlink scripts
  info "Symlinking custom scripts to $BIN_DIR..."
  link_script "$SCRIPT_DIR/dictate.sh" "dictate"

  # 3. Install default vocab file if not present
  local vocab_dir="$HOME/.config/dictate"
  local vocab_target="$vocab_dir/vocab.txt"
  local vocab_source="$SCRIPT_DIR/vocab.txt"
  mkdir -p "$vocab_dir"
  if [ ! -f "$vocab_target" ]; then
    if [ -f "$vocab_source" ]; then
      cp "$vocab_source" "$vocab_target"
      ok "Installed default vocab file to $vocab_target"
    fi
  else
    ok "Vocab file already exists at $vocab_target"
  fi

  echo ""
  ok "Scripts setup complete!"
  info "Available commands: dictate (run 'dictate --help' for usage)"
  echo ""
}

main "$@"
