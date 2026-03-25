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

---

## Clojure Development

### Overview

Clojure support is provided by three plugins working together:

| Plugin | Purpose |
|---|---|
| `Olical/conjure` | REPL-driven development (eval, test, namespace refresh) |
| `julienvincent/nvim-paredit` | Structural editing for s-expressions |
| `m00qek/baleia.nvim` | ANSI color rendering in conjure log |

All lazy-load on `ft = clojure` -- zero impact on other workflows.

LSP comes from **clojure-lsp** (auto-detected by LazyVim when on `$PATH`).
Completion comes from clojure-lsp via **blink.cmp** (no extra config needed).

### External Dependencies

```bash
brew install clojure-lsp/brew/clojure-lsp-native   # LSP server
brew install clojure/tools/clojure                  # Clojure CLI
brew install borkdude/brew/babashka                 # Fast scripting, auto-REPL fallback
```

### Starting a REPL

Conjure connects automatically by reading `.nrepl-port` in the project root.

```bash
# deps.edn project -- add this alias, then run:
clj -M:repl/conjure
```

Required alias in `deps.edn`:

```clojure
{:aliases
 {:repl/conjure
  {:extra-deps {nrepl/nrepl       {:mvn/version "1.0.0"}
                cider/cider-nrepl {:mvn/version "0.42.1"}}
   :main-opts  ["--main" "nrepl.cmdline"
                "--middleware" "[cider.nrepl/cider-middleware]"
                "--interactive"]}}}
```

If no nREPL is found, Conjure auto-starts a **Babashka** REPL as fallback.

Manual connection: `:ConjureConnect 5678` or `:ConjureConnect host 5678`.

### REPL Evaluation (`<localleader>` prefix)

| Keymap | Action |
|---|---|
| `<localleader>ee` | Eval innermost form under cursor |
| `<localleader>er` | Eval root (outermost) form |
| `<localleader>eb` | Eval entire buffer |
| `<localleader>ef` | Eval file from disk |
| `<localleader>E` (visual) | Eval visual selection |
| `<localleader>e!` | Eval form and replace with result |
| `<localleader>ew` | Eval word under cursor |
| `<localleader>em{mark}` | Eval form at a Vim mark |

### Eval-as-Comment

| Keymap | Action |
|---|---|
| `<localleader>ece` | Eval current form, insert result as comment |
| `<localleader>ecr` | Eval root form, insert result as comment |
| `<localleader>ecw` | Eval word, insert result as comment |

### Log Buffer

Results accumulate in a log buffer. When closed, results appear in a floating HUD.

| Keymap | Action |
|---|---|
| `<localleader>ls` | Open log in horizontal split |
| `<localleader>lv` | Open log in vertical split |
| `<localleader>lt` | Open log in new tab |
| `<localleader>lq` | Close all log windows |
| `<localleader>lg` | Toggle log split |
| `<localleader>lr` | Soft reset (wipe contents) |
| `<localleader>ll` | Jump to latest result |
| `[c` / `]c` | Previous / next eval output (in log buffer) |

### Testing

| Keymap | Action |
|---|---|
| `<localleader>ta` | Run all loaded tests |
| `<localleader>tn` | Run tests in current namespace |
| `<localleader>tN` | Run tests in alternate namespace |
| `<localleader>tc` | Run test under cursor |

### Namespace Refresh

| Keymap | Action |
|---|---|
| `<localleader>rr` | Refresh changed namespaces |
| `<localleader>ra` | Refresh all namespaces |
| `<localleader>rc` | Clear refresh cache |

### Documentation & Navigation

| Keymap | Action |
|---|---|
| `K` | LSP hover (standard) |
| `gd` | LSP go to definition (standard) |
| `<localleader>K` | Conjure doc lookup |
| `<localleader>gd` | Conjure go to definition |
| `<localleader>ve` | View last exception |
| `<localleader>v1` / `v2` / `v3` | View recent results (*1, *2, *3) |
| `<localleader>vs` | View source of symbol |

### Structural Editing (nvim-paredit)

#### Slurp & Barf

| Keymap | Action |
|---|---|
| `>)` | Slurp forward (pull next element into form) |
| `<(` | Slurp backward (pull previous element into form) |
| `<)` | Barf forward (push last element out of form) |
| `>(` | Barf backward (push first element out of form) |

#### Drag (Reorder)

| Keymap | Action |
|---|---|
| `>e` / `<e` | Drag element forward / backward |
| `>f` / `<f` | Drag form forward / backward |

#### Transform

| Keymap | Action |
|---|---|
| `<localleader>o` | Raise form (replace parent with this form) |
| `<localleader>O` | Raise element (replace parent with this element) |
| `<localleader>@` | Splice (unwrap form, keeping children) |

#### Motions & Text Objects

| Keymap | Action |
|---|---|
| `W` / `B` / `E` | Element-wise motions (forward / backward / end) |
| `(` / `)` | Jump to parent form start / end |
| `af` / `if` | Around / in form |
| `aF` / `iF` | Around / in top-level form |
| `ae` / `ie` | Around / in element |

### clojure-lsp Refactoring

Available via LSP code actions (`<leader>ca`). Common refactorings:

| Command | Action |
|---|---|
| Clean namespace | Sort/remove requires and imports |
| Extract function | Extract selection into a new defn |
| Thread first / last | Convert nested calls to `->` / `->>` |
| Inline symbol | Replace symbol with its definition |
| Move to let | Wrap expression in a let binding |
| Cycle collection | Toggle between `()` `[]` `{}` `#{}` |
| Introduce let | Wrap form in a let binding |
| Create test | Generate test skeleton |

### Interactive Tutorial

Run `:ConjureSchool` to walk through Conjure's workflow interactively.
