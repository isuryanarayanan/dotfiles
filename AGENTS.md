# AGENTS.md

Guidelines for AI agents working in this dotfiles repository.

## Project Overview

Personal dotfiles repo providing tmux and Neovim (LazyVim) configuration.
Languages: **Bash** (setup scripts), **Lua** (Neovim config), **tmux conf**.
No build system, no test suite, no CI/CD pipeline.

**This repo is the single source of truth for the development environment.**
Config files in this repo are symlinked into their system locations
(`~/.config/nvim` and `~/.tmux.conf`). Every edit you make here is immediately
live -- there is no deploy step, no copy, no sync. Treat every change as a
production change to the running environment.

## Repository Structure

```
dotfiles/
  setup.sh                  # Full bootstrap (designed for curl | bash)
  reinstall.sh              # Sync/reconcile existing install with remote
  nvim/
    setup_nvim.sh           # Symlinks ~/.config/nvim -> repo
    nvim/                   # LazyVim config (symlink target)
      init.lua              # Entry point, requires config.lazy
      stylua.toml           # StyLua formatter config
      lazy-lock.json        # Plugin lockfile (47 plugins)
      lua/config/           # lazy.lua, options.lua, keymaps.lua, autocmds.lua
      lua/plugins/          # One file per plugin/feature concern
      plugin/after/         # After-load scripts (transparency.lua)
  tmux/
    setup_tmux.sh           # Symlinks ~/.tmux.conf -> repo
    .tmux.conf              # Tmux configuration
```

## Build / Lint / Test Commands

There is no build step, test suite, or CI pipeline. The project is pure configuration.

### Formatting

Lua files: format with [StyLua](https://github.com/JohnnyMorganz/StyLua) using the
config at `nvim/nvim/stylua.toml`:

```bash
# Format all Lua files
stylua nvim/nvim/

# Format a single file
stylua nvim/nvim/lua/plugins/neo-tree.lua
```

### Linting

Shell scripts: lint with [ShellCheck](https://www.shellcheck.net/):

```bash
# Lint all shell scripts
shellcheck setup.sh reinstall.sh nvim/setup_nvim.sh tmux/setup_tmux.sh

# Lint a single script
shellcheck setup.sh
```

### Validating Changes

- **Neovim config**: Open `nvim` and confirm no errors on startup; run `:checkhealth`
- **Tmux config**: Run `tmux source-file ~/.tmux.conf` or press `prefix + r` inside tmux
- **Setup scripts**: Test with `bash -n <script>` for syntax checking before running

## Shell Script Conventions (Bash)

### Structure and Safety
- Shebang: always `#!/bin/bash`
- Use `set -e` in orchestrator scripts (`setup.sh`, `reinstall.sh`)
- Smaller helper scripts (`setup_nvim.sh`, `setup_tmux.sh`) use explicit `exit 1` instead
- Every script defines a `main()` function and calls `main "$@"` at the end

### Naming
- Global constants: `UPPER_SNAKE_CASE` (e.g., `DOTFILES_DIR`, `NVIM_SOURCE`)
- Local variables: `local lower_snake_case` (e.g., `local distro`, `local has_changes`)
- Functions: `lower_snake_case` (e.g., `install_packages_macos`, `detect_linux_distro`)

### Logging Helpers
All orchestrator scripts define these four colorized helpers using `printf` (not `echo`):
```bash
info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }
```
Use `info`/`ok`/`warn` for status messages. `err()` is always fatal (exits with 1).

### Error Handling
- `|| true` to suppress non-fatal failures
- `|| warn "..."` for degraded-but-continuing operation
- `err "..."` for fatal errors (prints message and exits)
- Redirect expected stderr with `2>/dev/null`; test commands with `>/dev/null 2>&1`

### Comments
- Section dividers: `# ── Section Name ────────────────────────`
- Step numbering in main: `# 1. Install packages`, `# 2. Setup repo`, etc.
- File headers: multi-line descriptive block after shebang

### Quoting
- Always double-quote variable expansions: `"$HOME"`, `"$DOTFILES_DIR"`, `"$(command)"`
- Single quotes only for literal strings

### Control Flow
- `case` statements for OS/distro detection
- Guard clauses with early return: `if condition; then ok "..."; return; fi`
- Symlink checks follow a 3-state pattern: is-symlink / is-file-or-dir / does-not-exist

### Self-Containment
Each script duplicates its helper functions (no shared source file). This is intentional
so that `setup.sh` works standalone via `curl | bash`.

## Lua Conventions (Neovim Config)

### Formatting
- Indentation: **2 spaces** (per `stylua.toml`). Run `stylua` before committing.
- Column width: 120 characters
- Use `-- stylua: ignore` directive when formatter output is undesirable

### File Naming
- Plugin files: `kebab-case.lua` (e.g., `all-themes.lua`, `vim-tmux-navigator.lua`)
- Config files: `snake_case.lua` (e.g., `lazy.lua`, `options.lua`)

### Plugin Spec Pattern
Every file under `lua/plugins/` must return a lazy.nvim spec table:
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

### Naming
- Variables: `snake_case` (e.g., `lazypath`, `theme_plugin_name`, `plugin_dir`)
- Use `vim.api.nvim_*`, `vim.fn.*`, `vim.opt.*`, `vim.cmd.*` standard namespaces

### Requires / Imports
- Dot-notation string paths: `require("config.lazy")`, `require("lazy.core.config")`

### Error Handling
- Wrap fallible calls with `pcall`: `local ok, result = pcall(require, "plugins.theme")`
- Early return on failure: `if not ok then return end`
- Display errors via `vim.api.nvim_echo({{ msg, "ErrorMsg" }}, true, {})`

### Type Annotations
- Use LuaCATS annotations where useful: `---@param`, `---@class`, `---@type`

## Tmux Configuration

- Plugin declarations: `set -g @plugin 'org/plugin-name'`
- Plugin options: `set -g @option 'value'`
- TPM bootstrap is always the last line: `run '~/.tmux/plugins/tpm/tpm'`

## Machine-Specific Files

- `lua/plugins/theme.lua` is **gitignored** (machine-specific theme selection)
- `lua/plugins/theme.lua.default` is the tracked template
- Setup scripts copy the default to create `theme.lua` if it doesn't exist
- Never commit `theme.lua` directly

## Architecture Decisions

- **Symlink-based config**: Config files live in the repo; setup scripts create symlinks
  from system paths (`~/.config/nvim`, `~/.tmux.conf`) to the repo
- **One directory per tool**: `nvim/` and `tmux/` each contain a setup script and the
  config files
- **One plugin file per concern**: Each Lua file in `lua/plugins/` addresses a single
  plugin or feature
- Edits to config files are automatically tracked by git because of symlinks

### Symlink Map

| System path | Symlink target in repo |
|---|---|
| `~/.config/nvim` | `nvim/nvim/` |
| `~/.tmux.conf` | `tmux/.tmux.conf` |

Because of these symlinks, **any file you edit in this repo is the live config
file the tool reads**. There is no build, no copy, no intermediate step. When
you modify `nvim/nvim/lua/plugins/neo-tree.lua`, Neovim picks up the change on
its next start. When you modify `tmux/.tmux.conf`, tmux picks it up on reload
(`prefix + r`). Act accordingly: validate changes carefully and avoid leaving
files in a broken state.
