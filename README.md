# dotfiles

Configuration files for tmux and neovim.

## One-liner setup

```bash

curl -fsSL https://raw.githubusercontent.com/isuryanarayanan/dotfiles/master/setup.sh | bash

```

This will detect your OS (Linux or macOS), install dependencies, clone the repo, and set up tmux and neovim.

## What's included

| Tool | Config | Setup method |
|------|--------|--------------|
| **tmux** | Custom keybindings, mouse mode, TPM plugins (resurrect, continuum, yank, vim-tmux-navigator) | Symlink via `setup_tmux.sh` |
| **neovim** | LazyVim-based Lua config with 14 colorschemes, transparency, theme hot-reload | Symlink via `setup_nvim.sh` |

Both tools use symlinks, so any config edits are automatically tracked in the repo.

## Platform guides

For manual step-by-step setup or platform-specific notes:

- **[Linux](SETUP_LINUX.md)** -- Ubuntu/Debian, Arch, Fedora
- **[macOS](SETUP_MACOS.md)** -- Homebrew-based setup

## Repository structure

```
dotfiles/
├── setup.sh                   # One-liner setup (curl | bash)
├── README.md
├── SETUP_LINUX.md
├── SETUP_MACOS.md
├── nvim/
│   ├── setup_nvim.sh          # Symlinks ~/.config/nvim to this repo
│   └── nvim/                  # LazyVim config (init.lua, lua/, plugin/)
└── tmux/
    ├── setup_tmux.sh          # Symlinks ~/.tmux.conf to this repo
    └── .tmux.conf
```

