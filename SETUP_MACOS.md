# Setup - macOS

Step-by-step guide to set up these dotfiles on a fresh macOS machine.

## Prerequisites

### Install Homebrew

If not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install required packages

```bash
brew install git tmux neovim
```

> Neovim 0.9+ is required for LazyVim. Homebrew typically ships the latest version.

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

### macOS note on Alt key

The `Alt + Arrow` pane navigation bindings send `M-Left`, `M-Right`, etc. In some macOS terminals, the Option key does not send Meta by default. To fix this:

- **Alacritty / Kitty / Ghostty:** Works out of the box.
- **iTerm2:** Go to Preferences > Profiles > Keys and set "Left Option Key" to "Esc+".
- **Terminal.app:** Go to Preferences > Profiles > Keyboard and enable "Use Option as Meta key".

### Plugins included

- **tmux-sensible** -- sensible defaults
- **tmux-resurrect** -- save/restore sessions across restarts
- **tmux-continuum** -- automatic session restore
- **tmux-yank** -- clipboard integration (uses `pbcopy` on macOS automatically)
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

Some LazyVim features require additional tools:

```bash
brew install ripgrep fd node
```

- **ripgrep** -- fast search (used by Telescope/grep)
- **fd** -- fast file finder
- **node** -- required by some LSP servers
