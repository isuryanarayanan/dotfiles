#!/bin/bash

# Creates a symlink from ~/.config/nvim to this repo's nvim config.
# Any edits to nvim config will automatically be tracked in the dotfiles repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SOURCE="$SCRIPT_DIR/nvim"
NVIM_TARGET="$HOME/.config/nvim"

# Portable readlink -f (works on macOS without GNU coreutils)
resolve_path() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
  elif command -v greadlink >/dev/null 2>&1; then
    greadlink -f "$path"
  elif readlink -f "$path" 2>/dev/null; then
    return 0
  else
    # Fallback: resolve manually
    cd "$(dirname "$path")" && echo "$(pwd)/$(basename "$path")"
  fi
}

if [ ! -d "$NVIM_SOURCE" ]; then
  echo "Error: Source config not found at $NVIM_SOURCE"
  exit 1
fi

# Ensure ~/.config exists
mkdir -p "$HOME/.config"

if [ -L "$NVIM_TARGET" ]; then
  current_link="$(resolve_path "$NVIM_TARGET")"
  if [ "$current_link" = "$(resolve_path "$NVIM_SOURCE")" ]; then
    echo "Symlink already exists and points to the correct location."
    exit 0
  else
    echo "Existing symlink points to $current_link"
    echo "Removing and re-linking to $NVIM_SOURCE"
    rm "$NVIM_TARGET"
  fi
elif [ -d "$NVIM_TARGET" ]; then
  echo "Warning: $NVIM_TARGET is an existing directory."
  echo "Backing up to ${NVIM_TARGET}.bak"
  mv "$NVIM_TARGET" "${NVIM_TARGET}.bak"
elif [ -e "$NVIM_TARGET" ]; then
  echo "Warning: $NVIM_TARGET exists but is not a directory or symlink."
  echo "Backing up to ${NVIM_TARGET}.bak"
  mv "$NVIM_TARGET" "${NVIM_TARGET}.bak"
fi

ln -s "$NVIM_SOURCE" "$NVIM_TARGET"
echo "Symlinked $NVIM_TARGET -> $NVIM_SOURCE"
