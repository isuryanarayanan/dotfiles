# dotfiles

Configuration files for tmux, neovim, zsh, ghostty, and Pi.

## One-liner setup

```bash
curl -fsSL https://raw.githubusercontent.com/isuryanarayanan/dotfiles/master/setup.sh | bash
```

This will detect your OS (conventional Linux or macOS), install dependencies, clone the repo, and set up tmux, neovim, zsh, ghostty, custom scripts, and Pi.

> NixOS uses the declarative flow in [SETUP_NIXOS.md](SETUP_NIXOS.md) instead. On macOS, run the installer as your normal user (not with `sudo`) because Homebrew does not allow root execution.

## What's included

| Tool        | Config                                                                                       | Setup method                                               |
| ----------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **tmux**    | Custom keybindings, mouse mode, TPM plugins, and sessionx                                  | Symlink via `setup_tmux.sh`                                |
| **neovim**  | LazyVim-based Lua config with 14 colorschemes, transparency, theme hot-reload                | Symlink via `setup_nvim.sh`                                |
| **zsh**     | zinit plugins, vi mode, starship prompt, aliases, fzf/eza/bat/zoxide integration             | Symlink via `setup_zsh.sh`                                 |
| **ghostty** | Terminal colors (black-focused theme), cursor/selection palette                              | Config file at `ghostty/config`                            |
| **pi**      | Pi settings, personal extensions, skills, prompts, and themes                               | Symlink managed `~/.pi/agent/` paths into `pi/`           |

All tools use symlinks, so managed config edits are automatically tracked in the repo. Shared cross-agent skills live under `agents/`, while Pi-specific skills live under `pi/skills/`. Pi credentials, sessions, trust decisions, model caches, and installed npm dependencies remain local under `~/.pi/agent/`.

## Platform guides

For manual step-by-step setup or platform-specific notes:

- **[Linux](SETUP_LINUX.md)** -- Ubuntu/Debian, Arch, Fedora
- **[NixOS](SETUP_NIXOS.md)** -- Flake and Home Manager setup
- **[macOS](SETUP_MACOS.md)** -- Homebrew-based setup

## Repository structure

```
dotfiles/
├── setup.sh                   # One-liner setup for macOS/conventional Linux
├── reinstall.sh               # Sync/reconcile an existing non-NixOS install
├── flake.nix                  # NixOS and Home Manager entry point
├── README.md
├── SETUP_LINUX.md
├── SETUP_NIXOS.md
├── SETUP_MACOS.md
├── nix/
│   ├── hosts/nixos/           # Host and generated hardware configuration
│   ├── modules/nixos/         # Shared NixOS system modules
│   ├── modules/home/          # Home Manager packages and writable links
│   └── users/suryan.nix       # User Home Manager configuration
├── nvim/
│   ├── setup_nvim.sh          # Symlinks ~/.config/nvim to this repo
│   └── nvim/                  # LazyVim config (init.lua, lua/, plugin/)
├── tmux/
│   ├── setup_tmux.sh          # Symlinks ~/.tmux.conf to this repo
│   └── .tmux.conf
├── ghostty/
│   └── config                 # Ghostty terminal config
├── agents/
│   ├── .skill-lock.json       # Shared skill installation metadata
│   └── skills/                # Skills shared across agent harnesses
├── pi/
│   ├── setup_pi.sh            # Installs Pi, creates links, and restores packages
│   ├── settings.json          # Preferences and Pi package declarations
│   ├── keybindings.json       # Managed Pi keybindings
│   ├── extensions/            # Personal extensions and extension config
│   ├── skills/                # Pi-specific global skills
│   ├── prompts/               # Global prompt templates
│   └── themes/                # Global custom themes
└── zsh/
    ├── setup_zsh.sh           # Installs tools and symlinks config files
    ├── .zshrc                 # Main shell config (zinit, plugins, aliases, vi mode)
    ├── .zshenv                # Universal env vars (Cargo)
    ├── .zprofile              # Login shell env (Homebrew)
    └── starship/
        └── starship.toml      # Starship prompt config
```
