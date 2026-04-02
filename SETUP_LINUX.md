# Setup - Linux

Step-by-step guide to set up these dotfiles on a fresh Linux machine.

## Prerequisites

Install the required packages using your distribution's package manager.

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install git tmux neovim ripgrep fd-find nodejs npm
```

### Arch Linux

```bash
sudo pacman -S git tmux neovim ripgrep fd nodejs npm
```

### Fedora

```bash
sudo dnf install git tmux neovim ripgrep fd-find nodejs npm
```

> Neovim 0.9+ is required for LazyVim. If your distro ships an older version,
> install from the [neovim releases](https://github.com/neovim/neovim/releases)
> or use a PPA/COPR.

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

### Additional dependencies

```bash
# Clipboard support (for tmux-yank and neovim)
sudo apt install xclip             # X11
sudo apt install wl-clipboard      # Wayland

# Node.js (for some LSP servers)
sudo apt install nodejs npm        # or use nvm
```

## Zsh

### 1. Run the setup script

This installs zsh productivity tools and symlinks `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and `~/.config/starship.toml` to this repo.

```bash
~/dotfiles/zsh/setup_zsh.sh
```

Any existing files are backed up with a `.bak` suffix before being replaced.

> On Linux, the script will print installation instructions for tools that cannot be auto-installed (starship, fzf, zoxide, eza, bat). Install them manually using the printed commands before continuing.

### Installing zsh tools on Linux

Some tools are not available in standard package repos. Install them manually:

```bash
# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all --no-bash --no-fish

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# eza (requires Rust/Cargo)
cargo install eza

# bat
sudo apt install bat        # Ubuntu/Debian (note: binary may be called 'batcat')
sudo pacman -S bat          # Arch
sudo dnf install bat        # Fedora
```

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

### Symlink map

| System path | Repo file |
|-------------|-----------|
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.zshenv` | `zsh/.zshenv` |
| `~/.zprofile` | `zsh/.zprofile` |
| `~/.config/starship.toml` | `zsh/starship/starship.toml` |
