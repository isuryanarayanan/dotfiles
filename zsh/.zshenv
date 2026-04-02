#!/bin/zsh

# ──────────────────────────────────────────────
# ~/.zshenv  —  managed by dotfiles
# symlink: ~/.zshenv -> ~/dotfiles/zsh/.zshenv
#
# Sourced for ALL zsh sessions (interactive, non-interactive, login, scripts).
# Keep this minimal: only environment variables that must be available
# universally (e.g. for scripts and editors). Do NOT put anything here
# that produces output or is slow.
# ──────────────────────────────────────────────

# Rust / Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
