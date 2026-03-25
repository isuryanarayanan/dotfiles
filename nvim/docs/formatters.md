# Formatters

Formatting is handled by [conform.nvim](https://github.com/stevearc/conform.nvim),
which is included as part of the LazyVim base distribution.

## Keybindings

| Key            | Mode     | Action                 |
|----------------|----------|------------------------|
| `<leader>cf`   | n, x     | Format buffer/selection |
| `<leader>cF`   | n, x     | Format injected langs  |

## Configuration

Formatter configuration lives in `lua/plugins/formatting.lua`. This file
extends LazyVim's built-in conform.nvim spec by adding entries to
`formatters_by_ft`.

```lua
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      markdown = { "prettier" },
    },
  },
}
```

LazyVim provides these formatters by default:

| Filetype | Formatter    |
|----------|--------------|
| lua      | stylua       |
| fish     | fish_indent  |
| sh       | shfmt        |

This repo adds:

| Filetype | Formatter |
|----------|-----------|
| markdown | prettier  |

To add a formatter for a new filetype, add an entry to `formatters_by_ft`:

```lua
formatters_by_ft = {
  markdown = { "prettier" },
  python = { "black" },       -- example
  javascript = { "prettier" }, -- example
},
```

## Installing Formatter Binaries

Formatter binaries are installed via [Mason](https://github.com/williamboman/mason.nvim).
Inside Neovim, run:

```
:MasonInstall <formatter-name>
```

For example: `:MasonInstall prettier`

Mason installs binaries to `~/.local/share/nvim/mason/bin/`.

## Debugging

If formatting isn't working, open the file you want to format and run:

- `:ConformInfo` -- shows which formatters are configured and available for
  the current buffer. Check that the formatter appears under
  "Formatters for this buffer" (not just "Other formatters").
- `:LazyFormatInfo` -- shows the LazyVim formatting status, including whether
  autoformat is enabled and which formatter providers are registered.
- `:checkhealth conform` -- verifies formatter binaries are installed and
  on PATH.

Common issues:

- **"No formatter available"**: The filetype has no entry in `formatters_by_ft`.
  Add one in `lua/plugins/formatting.lua`.
- **Formatter listed under "Other formatters" but not "for this buffer"**: The
  buffer's filetype doesn't match the key in `formatters_by_ft`. Check the
  filetype with `:set ft?`.
- **Formatter shows "unavailable"**: The binary isn't installed. Run
  `:MasonInstall <name>` or install it on your system PATH.
