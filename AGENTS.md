# AGENTS.md

Guidelines for AI agents working in this dotfiles repository.

## Agent Quick Start

1. Treat this repo as the **live source of truth** for the machine config. Most files are symlinked into `~`.
2. Before editing, inspect the relevant setup script and target config file:
   - Shell/bootstrap: `setup.sh`, `reinstall.sh`, `*/setup_*.sh`
   - Neovim: `nvim/setup_nvim.sh`, then `nvim/nvim/lua/config/` and `nvim/nvim/lua/plugins/`
   - Zsh: `zsh/setup_zsh.sh`, then `zsh/.zshenv`, `zsh/.zprofile`, `zsh/.zshrc`
   - Tmux: `tmux/setup_tmux.sh`, then `tmux/.tmux.conf`
   - Ghostty: `ghostty/config`
   - Pi: `pi/setup_pi.sh`, `pi/settings.json`, `pi/extensions/`
3. Prefer small, targeted edits. Validate syntax after touching scripts or Lua.
4. Do not edit generated/local machine-specific files unless explicitly asked, especially `nvim/nvim/lua/plugins/theme.lua`.

## Project Overview

Personal dotfiles repo providing tmux, Neovim (LazyVim), zsh, ghostty, scripts, and Pi coding-agent configuration.

Languages/config formats:

- **Bash**: setup/reinstall scripts and utility scripts
- **Lua**: Neovim config
- **Zsh**: shell config
- **tmux conf**: tmux config
- **TOML**: Starship prompt
- **JSON**: Pi settings and Neovim metadata
- **TypeScript**: Pi extensions

There is no build system, test suite, or CI/CD pipeline.

**This repo is the single source of truth for the development environment.**
Config files in this repo are symlinked into their system locations. Every edit you make here can be immediately live. There is no deploy/copy/sync step for symlinked configs.

## Repository Structure

```text
dotfiles/
  AGENTS.md                 # Instructions for coding agents
  README.md                 # Human-facing overview and install docs
  SETUP_LINUX.md            # Linux setup notes
  SETUP_MACOS.md            # macOS setup notes
  SCRATCHPAD.md             # Personal scratchpad/notes
  setup.sh                  # Full bootstrap, designed for curl | bash
  reinstall.sh              # Sync/reconcile an existing install with remote

  agents/
    .skill-lock.json        # Shared skill installation metadata
    skills/                 # Skills shared across agent harnesses

  pi/
    setup_pi.sh             # Installs Pi, creates managed links, restores packages
    settings.json           # Preferences and Pi package declarations
    keybindings.json        # Managed Pi keybindings
    extensions/             # Personal extensions and extension configuration
    skills/                 # Pi-specific global skills
    prompts/                # Global prompt templates
    themes/                 # Global custom themes

  ghostty/
    config                  # Ghostty terminal config

  scripts/
    setup_scripts.sh        # Symlinks scripts into ~/.local/bin
    dictate.sh              # Local voice-to-text using whisper.cpp
    vocab.txt               # Dictation vocabulary hints

  nvim/
    setup_nvim.sh           # Symlinks ~/.config/nvim -> repo nvim config
    nvim-handbook.md        # Neovim notes/handbook
    CLOJURE_CHANGELOG.md    # Clojure-related notes/changelog
    docs/
      formatters.md         # Formatter notes
    nvim/                   # LazyVim config; symlink target for ~/.config/nvim
      init.lua              # Entry point, requires config.lazy
      stylua.toml           # StyLua formatter config
      lazy-lock.json        # Lazy.nvim plugin lockfile
      lazyvim.json          # LazyVim extras/settings metadata
      .neoconf.json         # Neoconf metadata
      lua/config/           # lazy.lua, options.lua, keymaps.lua, autocmds.lua
      lua/plugins/          # One file per plugin/feature concern
      plugin/after/         # After-load scripts, e.g. transparency.lua

  tmux/
    setup_tmux.sh           # Symlinks ~/.tmux.conf -> repo
    .tmux.conf              # Tmux configuration

  zsh/
    setup_zsh.sh            # Installs tools and symlinks config files
    .zshrc                  # Interactive shell config
    .zshenv                 # Universal zsh environment
    .zprofile               # Login shell environment
    starship/
      starship.toml         # Starship prompt config
```

## Traversal Guide

Use this order when trying to understand behavior:

1. **Bootstrap flow**: start in `setup.sh`, then follow calls to tool-specific setup scripts.
2. **Reinstall/repair flow**: start in `reinstall.sh`; it verifies symlinks and re-runs setup where needed.
3. **Symlink target**: for a live config issue, inspect the symlink map below and edit the repo target, not the file under `~`.
4. **Neovim**:
   - `nvim/nvim/init.lua` loads `lua/config/lazy.lua`.
   - Core settings live in `lua/config/options.lua`, `keymaps.lua`, and `autocmds.lua`.
   - Feature/plugin changes live in `lua/plugins/*.lua` as Lazy.nvim specs.
5. **Zsh**:
   - `.zshenv` must stay minimal and silent.
   - `.zprofile` is login-shell setup.
   - `.zshrc` contains interactive plugins, aliases, keybindings, prompt setup.
6. **Pi**:
   - Managed files and resource directories under `pi/` are symlinked into `~/.pi/agent/`.
   - Shared cross-agent skills live under `agents/`; Pi-specific skills live under `pi/skills/`.
   - Package declarations are tracked in `pi/settings.json`; installed npm contents remain local.
   - Auth, sessions, trust decisions, caches, and other runtime state remain machine-local.

## Build / Lint / Test Commands

There is no build step. Validate the files you touched.

### Formatting

Lua files: format with [StyLua](https://github.com/JohnnyMorganz/StyLua) using `nvim/nvim/stylua.toml`:

```bash
# Format all Lua files
stylua nvim/nvim/

# Format a single file
stylua nvim/nvim/lua/plugins/neo-tree.lua
```

### Linting / Syntax Checks

Shell scripts:

```bash
# Syntax-check all shell scripts
bash -n setup.sh reinstall.sh pi/setup_pi.sh nvim/setup_nvim.sh tmux/setup_tmux.sh zsh/setup_zsh.sh scripts/setup_scripts.sh scripts/dictate.sh

# Lint all shell scripts when shellcheck is available
shellcheck setup.sh reinstall.sh pi/setup_pi.sh nvim/setup_nvim.sh tmux/setup_tmux.sh zsh/setup_zsh.sh scripts/setup_scripts.sh scripts/dictate.sh
```

Lua / Neovim:

```bash
# Format and optionally inspect startup manually
stylua nvim/nvim/
nvim --headless '+quit'
```

### Validating Changes

- **Neovim config**: Open `nvim` and confirm no startup errors; run `:checkhealth` for deeper checks.
- **Tmux config**: Run `tmux source-file ~/.tmux.conf` or press `prefix + r` inside tmux.
- **Zsh config**: Run `source ~/.zshrc` in a running interactive shell, or open a new terminal.
- **Setup scripts**: Run `bash -n <script>` before executing.
- **Pi config**: Restart/reload Pi after changing `pi/settings.json` or `pi/extensions/`.

## Shell Script Conventions (Bash)

### Structure and Safety

- Shebang: always `#!/bin/bash`.
- Use `set -e` in orchestrator scripts (`setup.sh`, `reinstall.sh`).
- Smaller helper scripts use explicit fatal paths (`exit 1` via `err`) instead of broad `set -e` unless already present.
- Every script defines a `main()` function and calls `main "$@"` at the end.

### Naming

- Global constants: `UPPER_SNAKE_CASE` (e.g. `DOTFILES_DIR`, `NVIM_SOURCE`).
- Local variables: `local lower_snake_case` (e.g. `local distro`, `local has_changes`).
- Functions: `lower_snake_case` (e.g. `install_packages_macos`, `detect_linux_distro`).

### Logging Helpers

Use these colorized helpers with `printf` rather than `echo` where practical:

```bash
info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }
```

Use `info`/`ok`/`warn` for status messages. `err()` is fatal.

### Error Handling

- `|| true` to suppress intentionally non-fatal failures.
- `|| warn "..."` for degraded-but-continuing operation.
- `err "..."` for fatal errors.
- Redirect expected stderr with `2>/dev/null`; test commands with `>/dev/null 2>&1`.

### Comments

- Section dividers: `# ── Section Name ────────────────────────`.
- Step numbering in `main`: `# 1. Install packages`, `# 2. Setup repo`, etc.
- File headers: brief multi-line descriptive block after the shebang.

### Quoting

- Always double-quote variable expansions: `"$HOME"`, `"$DOTFILES_DIR"`, `"$(command)"`.
- Single quotes only for literal strings.

### Control Flow

- Use `case` statements for OS/distro detection.
- Prefer guard clauses with early return.
- Symlink checks follow a 3-state pattern: is-symlink / is-file-or-dir / does-not-exist.

### Self-Containment

Each setup script duplicates helper functions instead of sourcing shared helpers. This is intentional so `setup.sh` works standalone via `curl | bash`.

## Lua Conventions (Neovim Config)

### Formatting

- Indentation: **2 spaces** per `stylua.toml`.
- Column width: 120 characters.
- Use `-- stylua: ignore` only when formatter output is undesirable.

### File Naming

- Plugin files: `kebab-case.lua` (e.g. `all-themes.lua`, `vim-tmux-navigator.lua`).
- Config files: `snake_case.lua` (e.g. `lazy.lua`, `options.lua`).

### Plugin Spec Pattern

Every file under `nvim/nvim/lua/plugins/` should return a Lazy.nvim spec table:

```lua
-- Single plugin
return {
  "org/plugin-name",
  opts = { ... },
}

-- Multiple plugins
return {
  { "org/plugin-a", ... },
  { "org/plugin-b", ... },
}
```

### Naming and APIs

- Variables: `snake_case`.
- Use `vim.api.nvim_*`, `vim.fn.*`, `vim.opt.*`, and `vim.cmd.*` standard namespaces.
- Require modules with dot-notation strings: `require("config.lazy")`.

### Error Handling

- Wrap fallible imports/calls with `pcall` where useful.
- Prefer early return on failure.
- Display user-facing errors via `vim.api.nvim_echo({ { msg, "ErrorMsg" } }, true, {})`.

### Type Annotations

Use LuaCATS annotations where useful: `---@param`, `---@class`, `---@type`.

## Zsh Configuration

### File Responsibilities

- `.zshenv` -- sourced for **all** zsh sessions. Keep minimal: universal env vars only. No output and no slow operations.
- `.zprofile` -- sourced once for **login** shells. Used for login PATH/env setup such as Homebrew shellenv.
- `.zshrc` -- sourced for **interactive** shells. Plugins, aliases, keybindings, prompt, and functions go here.

### Plugin Manager: zinit

- Plugins use turbo mode (`wait lucid`) for async loading.
- `fast-syntax-highlighting` must load **last** because it wraps ZLE widgets.
- Keybindings for turbo-loaded plugins must be set inside the plugin's `atload` hook, not top-level.

### Plugin Load Order

1. `zsh-completions` (`blockf`)
2. `zsh-history-substring-search` (`atload`: bind ↑↓ and j/k)
3. `zsh-autosuggestions` (`atload`: start + bind accept keys)
4. `fzf-tab`
5. `fast-syntax-highlighting` last (`atinit`: `zicompinit`)

### Starship Prompt

- Config lives at `zsh/starship/starship.toml`.
- Symlinked to `~/.config/starship.toml`.
- Shows directory, git branch/status, language versions, command duration, and vi mode character.

## Tmux Configuration

- Plugin declarations: `set -g @plugin 'org/plugin-name'`.
- Plugin options: `set -g @option 'value'`.
- TPM bootstrap should remain the last line: `run '~/.tmux/plugins/tpm/tpm'`.

## Pi Configuration

- Managed settings, keybindings, extensions, skills, prompts, and themes live under `pi/`.
- Their corresponding paths under `~/.pi/agent/` are symlinked to the repo.
- Third-party package declarations are tracked in `pi/settings.json`; `~/.pi/agent/npm/` is a generated local cache.
- Auth, sessions, trust decisions, model stores, temporary files, and other runtime state are not managed by this repo.
- Avoid duplicating capabilities already supplied by declared Pi packages such as Viki.
- Do not copy skills already discovered from `~/.agents/skills/` into `pi/skills/`; duplicate names cause collisions.
- Link only dotfiles-managed entries under `~/.agents/skills/` so externally managed entries such as `twg*` remain untouched.

## Machine-Specific Files

- `nvim/nvim/lua/plugins/theme.lua` is **gitignored** and machine-specific.
- `nvim/nvim/lua/plugins/theme.lua.default` is the tracked template.
- Setup scripts copy the default to create `theme.lua` if it does not exist.
- Never commit `theme.lua` directly.

## Architecture Decisions

- **Symlink-based config**: Config files live in the repo; setup scripts create symlinks from system paths to repo paths.
- **One directory per tool**: `nvim/`, `tmux/`, `zsh/`, `ghostty/`, `pi/`, and `scripts/` group related files.
- **One plugin file per concern**: Each Lua file in `lua/plugins/` addresses a plugin or feature.
- **Self-contained setup scripts**: Repeated helper code is intentional for standalone bootstrap reliability.

### Symlink Map

| System path                 | Symlink target in repo       |
| --------------------------- | ---------------------------- |
| `~/.config/nvim`            | `nvim/nvim/`                 |
| `~/.tmux.conf`              | `tmux/.tmux.conf`            |
| `~/.zshrc`                  | `zsh/.zshrc`                 |
| `~/.zshenv`                 | `zsh/.zshenv`                |
| `~/.zprofile`               | `zsh/.zprofile`              |
| `~/.config/starship.toml`   | `zsh/starship/starship.toml` |
| `~/.local/bin/dictate`      | `scripts/dictate.sh`         |
| `~/.config/ghostty/config`  | `ghostty/config`             |
| `~/.pi/agent/settings.json` | `pi/settings.json`           |
| `~/.pi/agent/keybindings.json` | `pi/keybindings.json`      |
| `~/.pi/agent/extensions`    | `pi/extensions/`              |
| `~/.pi/agent/skills`        | `pi/skills/`                  |
| `~/.pi/agent/prompts`       | `pi/prompts/`                 |
| `~/.pi/agent/themes`        | `pi/themes/`                  |
| `~/.agents/.skill-lock.json` | `agents/.skill-lock.json`    |
| `~/.agents/skills/find-skills` | `agents/skills/find-skills/` |
| `~/.agents/skills/grill-me` | `agents/skills/grill-me/`     |

Because of these symlinks, any edit to the repo target is usually a live configuration change. Validate carefully and avoid leaving files in a broken state.
