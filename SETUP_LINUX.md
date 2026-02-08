# Setup - Linux

Step-by-step guide to set up these dotfiles on a fresh Linux machine.

## Prerequisites

Install the required packages using your distribution's package manager.

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install git tmux neovim
```

### Arch Linux

```bash
sudo pacman -S git tmux neovim
```

### Fedora

```bash
sudo dnf install git tmux neovim
```

> Neovim 0.9+ is required for LazyVim. If your distro ships an older version,
> install from the [neovim releases](https://github.com/neovim/neovim/releases)
> or use a PPA/COPR.

## Clone the Repository

```bash
mkdir -p ~/tools
git clone git@github.com:isuryanarayanan/dotfiles.git ~/tools/dotfiles
```

## Tmux

### 1. Symlink the config

This creates a symlink from `~/.tmux.conf` to the config in this repo. Any changes you make are automatically tracked.

```bash
~/tools/dotfiles/tmux/setup_tmux.sh
```

If an existing `~/.tmux.conf` is found, it will be backed up to `~/.tmux.conf.bak`.

### 2. Install TPM (Tmux Plugin Manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 3. Install plugins

Start a tmux session and press `prefix + I` (capital I) to install plugins:

```bash
tmux
# Once inside tmux, press: Ctrl-b then Shift-i
```

Alternatively, install from the command line:

```bash
tmux start-server \; source-file ~/.tmux.conf
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
~/.tmux/plugins/tpm/bin/install_plugins
```

### Key bindings

| Binding | Action |
|---------|--------|
| `Ctrl-b v` | Vertical split |
| `Ctrl-b h` | Horizontal split |
| `Ctrl-b m` | Toggle pane zoom |
| `Ctrl-b r` | Reload config |
| `Alt + Arrow` | Navigate panes |
| `Shift + Left/Right` | Cycle windows |

Mouse mode is enabled by default.

### Plugins included

- **tmux-sensible** -- sensible defaults
- **tmux-resurrect** -- save/restore sessions across restarts
- **tmux-continuum** -- automatic session restore
- **tmux-yank** -- clipboard integration
- **vim-tmux-navigator** -- seamless pane navigation between tmux and vim

## Neovim

### 1. Run the setup script

This creates a symlink from `~/.config/nvim` to the config in this repo. Any changes you make are automatically tracked.

```bash
~/tools/dotfiles/nvim/setup_nvim.sh
```

If an existing `~/.config/nvim` directory is found, it will be backed up to `~/.config/nvim.bak`.

### 2. Launch neovim

On first launch, lazy.nvim will automatically bootstrap and install all plugins:

```bash
nvim
```

Wait for the plugin installation to complete, then restart neovim.

### Config overview

- **Distribution:** LazyVim
- **Plugin manager:** lazy.nvim
- **14 colorschemes** with a hot-reload system
- **Transparent background** enforced across all UI elements
- **Neo-tree** configured to show dotfiles
- Absolute line numbers (LazyVim default of relative is disabled)

### Dependencies

Some LazyVim features require additional tools. Install as needed:

```bash
# Fuzzy finder
sudo apt install ripgrep fd-find   # Ubuntu/Debian
sudo pacman -S ripgrep fd          # Arch

# Clipboard support (for tmux-yank and neovim)
sudo apt install xclip             # X11
sudo apt install wl-clipboard      # Wayland

# Node.js (for some LSP servers)
sudo apt install nodejs npm        # or use nvm
```
