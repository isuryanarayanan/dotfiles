#!/bin/bash

# Creates a symlink from ~/.tmux.conf to this repo's tmux config.
# Any edits to tmux config will automatically be tracked in the dotfiles repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SOURCE="$SCRIPT_DIR/.tmux.conf"
TMUX_TARGET="$HOME/.tmux.conf"

if [ ! -f "$TMUX_SOURCE" ]; then
  echo "Error: Source config not found at $TMUX_SOURCE"
  exit 1
fi

if [ -L "$TMUX_TARGET" ]; then
  current_link="$(readlink "$TMUX_TARGET")"
  if [ "$current_link" = "$TMUX_SOURCE" ]; then
    echo "Symlink already exists and points to the correct location."
    exit 0
  else
    echo "Existing symlink points to $current_link"
    echo "Removing and re-linking to $TMUX_SOURCE"
    rm "$TMUX_TARGET"
  fi
elif [ -f "$TMUX_TARGET" ]; then
  echo "Warning: Existing ~/.tmux.conf found, backing up to ~/.tmux.conf.bak"
  mv "$TMUX_TARGET" "${TMUX_TARGET}.bak"
elif [ -e "$TMUX_TARGET" ]; then
  echo "Warning: ~/.tmux.conf exists but is not a regular file, backing up to ~/.tmux.conf.bak"
  mv "$TMUX_TARGET" "${TMUX_TARGET}.bak"
fi

ln -s "$TMUX_SOURCE" "$TMUX_TARGET"
echo "Symlinked $TMUX_TARGET -> $TMUX_SOURCE"
