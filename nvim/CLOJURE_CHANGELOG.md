# Clojure Development Setup — Changelog

Planned additions to enable Clojure development in this Neovim configuration.
Based on LazyVim's official Clojure extra and current ecosystem best practices.

No files have been modified yet. This document tracks what will change.

---

## New Plugin Files

### `lua/plugins/clojure.lua`

Single plugin spec file following the one-file-per-concern convention.
Contains all Clojure-related plugin specs:

| Plugin | Purpose | Load event |
|---|---|---|
| `nvim-treesitter` (extend) | Add `clojure` parser to `ensure_installed` | — |
| `Olical/conjure` | REPL-driven development (nREPL connection, eval, test runner) | `LazyFile` |
| `julienvincent/nvim-paredit` | Structural editing (slurp, barf, raise, splice, drag) | `LazyFile` |
| `PaterJason/cmp-conjure` | REPL completions via nvim-cmp | with nvim-cmp |
| `m00qek/baleia.nvim` | ANSI color rendering in conjure log buffer | — |

---

## What Each Plugin Provides

### clojure-lsp (external dependency)

Must be installed on `$PATH` (via Homebrew, Mason, or manual install).
LazyVim auto-detects it — no explicit lspconfig spec needed.

Provides:
- Go to definition, find references, find implementations
- 40+ refactoring commands (extract function, thread first/last, clean ns, etc.)
- Diagnostics via bundled clj-kondo
- Formatting via bundled cljfmt
- Completion (including deps.edn library names/versions)
- Semantic tokens, code lenses, call hierarchy
- 50+ built-in snippets (defn, deftest, let, ns, require, etc.)

### Conjure (REPL)

Auto-connects to nREPL via `.nrepl-port` file. Falls back to Babashka auto-REPL.

Key mappings (all prefixed with `<localleader>`):

| Mapping | Action |
|---|---|
| `ee` | Eval innermost form |
| `er` | Eval root (outermost) form |
| `eb` | Eval buffer |
| `ef` | Eval file from disk |
| `E` (visual) | Eval selection |
| `e!` | Eval and replace with result |
| `ece` / `ecr` | Eval form/root, insert result as comment |
| `ls` / `lv` / `lt` | Open log in split / vsplit / tab |
| `ta` / `tn` / `tc` | Run all / namespace / cursor tests |
| `rr` / `ra` | Refresh changed / all namespaces |
| `K` | Doc lookup (becomes `<localleader>K` to avoid LSP conflict) |
| `gd` | Go to def (becomes `<localleader>gd` to avoid LSP conflict) |

Configuration notes:
- Uses `vim.g["conjure#..."]` globals set in `init` (not `opts`)
- `K` and `gd` remapped to `<localleader>K` / `<localleader>gd` so bare `K`/`gd` go to LSP
- Diagnostics disabled in log buffer
- `[c` / `]c` navigate between eval outputs in the log

### nvim-paredit (Structural Editing)

Treesitter-native s-expression manipulation. Default config (empty `opts`).

| Mapping | Action |
|---|---|
| `>)` / `<(` | Slurp forward / backward |
| `<)` / `>(` | Barf forward / backward |
| `>e` / `<e` | Drag element forward / backward |
| `>f` / `<f` | Drag form forward / backward |
| `<localleader>o` | Raise form |
| `<localleader>O` | Raise element |
| `<localleader>@` | Splice (unwrap form) |
| `W` / `B` / `E` | Element-wise motions |
| `af` / `if` | Around / in form text object |
| `aF` / `iF` | Around / in top-level form |
| `ae` / `ie` | Around / in element |

### baleia.nvim

Renders ANSI escape codes as colors in conjure's log buffer.
Paired with conjure config that preserves escape sequences (instead of stripping them).

### cmp-conjure

Bridges conjure's REPL-based completions into nvim-cmp.
Requires CIDER middleware on the nREPL server for Clojure completions.

---

## External Dependencies Required

| Dependency | Install | Purpose |
|---|---|---|
| `clojure-lsp` | `brew install clojure-lsp/brew/clojure-lsp-native` | LSP server |
| `clojure` (CLI tools) | `brew install clojure/tools/clojure` | Clojure runtime |
| `babashka` | `brew install borkdude/brew/babashka` | Fast Clojure scripting, auto-REPL fallback |
| CIDER nREPL middleware | Added to `deps.edn` or `project.clj` | Enhanced REPL features (completion, test, debug) |

### deps.edn alias for nREPL + CIDER

```clojure
{:aliases
 {:repl/conjure
  {:extra-deps {nrepl/nrepl       {:mvn/version "1.0.0"}
                cider/cider-nrepl {:mvn/version "0.42.1"}}
   :main-opts  ["--main" "nrepl.cmdline"
                "--middleware" "[cider.nrepl/cider-middleware]"
                "--interactive"]}}}
```

Start with: `clj -M:repl/conjure`

---

## Files That Will Be Created

```
nvim/nvim/lua/plugins/clojure.lua    # Plugin specs (new)
```

## Files That Will NOT Change

No existing plugin files, keymaps, options, or autocmds need modification.
The Clojure setup is entirely additive — one new plugin file.

---

## Workflow Summary

```
1. Start nREPL        →  clj -M:repl/conjure
2. Open .clj file     →  Conjure auto-connects, clojure-lsp starts
3. Write code         →  LSP diagnostics, completion, paredit structure
4. Eval forms         →  <localleader>ee / er / eb
5. Run tests          →  <localleader>ta / tn / tc
6. Refactor           →  LSP code actions (clean ns, extract fn, thread, etc.)
7. Navigate           →  gd (LSP def), gr (refs), <localleader>gd (conjure def)
```
