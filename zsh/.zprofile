#!/bin/zsh

# ──────────────────────────────────────────────
# ~/.zprofile  —  managed by dotfiles
# symlink: ~/.zprofile -> ~/dotfiles/zsh/.zprofile
#
# Sourced only for LOGIN shells (once per login session).
# Used for environment setup that should run once: PATH, brew shellenv, etc.
# ──────────────────────────────────────────────

# ── Homebrew ──────────────────────────────────

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv zsh)"
fi

export PATH="/Users/admin/.local/bin:$PATH"
