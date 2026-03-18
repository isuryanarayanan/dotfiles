# Neovim Handbook

Quick reference for this Neovim setup (LazyVim + custom config).

---

## Buffer Switching

All from LazyVim defaults. No custom overrides.

| Keymap | Action |
|---|---|
| `Shift+h` | Previous buffer |
| `Shift+l` | Next buffer |
| `[b` / `]b` | Previous / next buffer |
| `<leader>bb` | Switch to last used buffer |
| `<leader>,` | Fuzzy buffer picker |
| `<leader>fb` | Find buffers (same picker) |
| `<leader>bd` | Delete current buffer |

---

## Markdown

### Current Setup

Treesitter conceal with `conceallevel=2` (LazyVim default). Raw syntax is hidden
on non-cursor lines, revealed when you move to a line for editing.

| Keymap | Action |
|---|---|
| `<leader>uc` | Toggle conceal on/off |

### What Gets Concealed

| Syntax | Behavior |
|---|---|
| `*bold*`, `_italic_` | Markers hidden, formatting applied |
| `` `code` `` | Backtick delimiters hidden |
| `[text](url)` | Brackets, parens, URL hidden -- only link text shown |
| `![alt](url)` | Same as links, for images |
| ` ``` ` fenced blocks | Delimiters and language tag hidden |
| `&amp;`, `&lt;`, etc. | Replaced with actual characters |

### Available Upgrade: LazyVim Markdown Extra

Enable in `lua/config/lazy.lua` by adding to the imports:

```lua
{ import = "lazyvim.plugins.extras.lang.markdown" },
```

This bundles:

| Tool | Purpose |
|---|---|
| render-markdown.nvim | In-buffer rendering (headings, tables, checkboxes, code blocks) |
| markdown-preview.nvim | Live browser preview (`<leader>cp`) |
| marksman | LSP for links, references, TOC |
| markdownlint-cli2 | Linting |
| prettier + markdown-toc | Formatting |

Toggle render-markdown with `<leader>um`.

### Plugin Landscape

| Plugin | Type | Notes |
|---|---|---|
| render-markdown.nvim | In-buffer rendering | Community standard, LazyVim's pick |
| markview.nvim | In-buffer rendering | Broader format support (HTML, LaTeX, Typst), splitview, wrap support |
| markdown-preview.nvim | Browser preview | Best for diagrams/charts, stale since 2022 |
| obsidian.nvim | Workflow/PKM | Wiki-links, daily notes, templates -- not a renderer |

Pick one in-buffer renderer (render-markdown or markview), not both.

---

## Splits / Panes

### Creating Splits

| Keymap / Command | Action |
|---|---|
| `<leader>-` | Split horizontally (below) |
| `<leader>\|` | Split vertically (right) |
| `:split <file>` | Horizontal split with specific file |
| `:vsplit <file>` | Vertical split with specific file |

New splits open below (`splitbelow`) and to the right (`splitright`) by default.

### Navigating Splits

Handled by vim-tmux-navigator -- works across Neovim splits **and** tmux panes.

| Keymap | Direction |
|---|---|
| `Ctrl+h` | Left |
| `Ctrl+j` | Down |
| `Ctrl+k` | Up |
| `Ctrl+l` | Right |
| `Ctrl+\` | Previous split/pane |

### Resizing Splits

| Keymap | Action |
|---|---|
| `Ctrl+Up` / `Ctrl+Down` | Increase / decrease height |
| `Ctrl+Left` / `Ctrl+Right` | Decrease / increase width |

### Managing Splits

| Keymap | Action |
|---|---|
| `<leader>wd` | Close current split |
| `<leader>wm` | Toggle zoom (maximize/restore) |
| `<leader>bD` | Delete buffer and its window |
