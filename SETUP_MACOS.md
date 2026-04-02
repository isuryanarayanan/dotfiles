# Setup - macOS

Step-by-step guide to set up these dotfiles on a fresh macOS machine.

> Run all commands in this guide as your normal user (without `sudo`). Homebrew fails when executed as root.

## Prerequisites

### Install Homebrew

If not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install required packages

```bash
brew install git tmux neovim ripgrep fd node starship fzf eza bat zoxide tlrc
```

> Neovim 0.9+ is required for LazyVim. Homebrew typically ships the latest version.

## Clone the Repository

```bash
git clone git@github.com:isuryanarayanan/dotfiles.git ~/dotfiles
```

## Tmux

### 1. Symlink the config

This creates a symlink from `~/.tmux.conf` to the config in this repo. Any changes you make are automatically tracked.

```bash
~/dotfiles/tmux/setup_tmux.sh
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

| Binding              | Action           |
| -------------------- | ---------------- |
| `Ctrl-b v`           | Vertical split   |
| `Ctrl-b h`           | Horizontal split |
| `Ctrl-b m`           | Toggle pane zoom |
| `Ctrl-b r`           | Reload config    |
| `Alt + Arrow`        | Navigate panes   |
| `Shift + Left/Right` | Cycle windows    |

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
~/dotfiles/nvim/setup_nvim.sh
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

Some LazyVim features require additional tools (installed above with the prerequisite packages):

- **ripgrep** -- fast search (used by Telescope/grep)
- **fd** -- fast file finder
- **node** -- required by some LSP servers

## Zsh

### 1. Run the setup script

This installs zsh productivity tools and symlinks `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and `~/.config/starship.toml` to this repo.

```bash
~/dotfiles/zsh/setup_zsh.sh
```

Any existing files are backed up with a `.bak` suffix before being replaced.

### 2. Open a new terminal

zinit (the plugin manager) bootstraps itself and installs all plugins on the first shell launch. Open a new terminal window — you'll see a brief one-time install, then the shell is ready.

### What's configured

- **Prompt:** Starship — shows directory, git branch/status, language versions, command duration, and vi mode indicator
- **Plugin manager:** zinit with turbo/lazy loading
- **Plugins:**
  - `fast-syntax-highlighting` -- colors commands as you type
  - `zsh-autosuggestions` -- inline history suggestions (right arrow or `Ctrl+Space` to accept)
  - `zsh-history-substring-search` -- up/down arrows (and `j`/`k` in normal mode) search history by prefix
  - `fzf-tab` -- tab completion routed through fzf with live previews
- **Tools:** fzf (Ctrl+R/T, Alt+C), eza (`ls`/`ll`/`la`/`lt`), bat (`cat`), zoxide (`z`), tlrc (`tldr`)
- **Vi mode** with cursor shape switching, `v` to edit command in nvim
- **NVM lazy-loading** -- nvm only initialises on first use of `node`/`npm`/`nvm`

### Key bindings

| Binding | Action |
|---------|--------|
| `Ctrl+R` | Fuzzy search shell history |
| `Ctrl+T` | Fuzzy insert file path |
| `Alt+C` | Fuzzy cd into directory |
| `Ctrl+Space` | Accept autosuggestion |
| `→` (in insert mode) | Accept autosuggestion |
| `↑` / `↓` | History substring search |
| `k` / `j` (normal mode) | History substring search |
| `v` (normal mode) | Edit command in `$EDITOR` |
| `Ctrl+E` | Edit command in `$EDITOR` |
| `Esc` | Enter vi normal mode |

### Useful aliases

| Alias | Expands to |
|-------|-----------|
| `ll` | `eza -l --icons --git` |
| `la` | `eza -la --icons --git` |
| `lt` | `eza --tree --level=2 --icons` |
| `cat` | `bat --paging=never` |
| `z <dir>` | Jump to frecent directory (zoxide) |
| `gs` | `git status` |
| `gl` | `git log --oneline --graph --decorate` |
| `dotfiles` | `cd ~/dotfiles` |
| `zshrc` | Open `.zshrc` in `$EDITOR` |
| `reload` | `source ~/.zshrc` |

### Symlink map

| System path | Repo file |
|-------------|-----------|
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.zshenv` | `zsh/.zshenv` |
| `~/.zprofile` | `zsh/.zprofile` |
| `~/.config/starship.toml` | `zsh/starship/starship.toml` |
