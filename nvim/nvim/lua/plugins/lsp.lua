-- ── LSP Server Configuration ────────────────────────
-- Configures nvim-lspconfig servers (auto-installed by mason)
-- and ensures mason has the required tooling installed.
--
-- gd / gD / gr / gI / gy keymaps are provided by LazyVim defaults
-- and activate automatically when an LSP server attaches to a buffer.

return {
  -- LSP servers
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- TypeScript / JavaScript
        ts_ls = {},

        -- Python
        basedpyright = {},

        -- Go
        gopls = {},

        -- Lua (Neovim config, etc.)
        lua_ls = {},

        -- Clojure
        clojure_lsp = {},
      },
    },
  },

  -- Ensure mason installs the servers + formatters/linters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP servers
        "typescript-language-server",
        "basedpyright",
        "gopls",
        "lua-language-server",
        "clojure-lsp",
        -- Formatters / linters
        "stylua",
        "shellcheck",
        "shfmt",
        "prettier",
      },
    },
  },

  -- Treesitter parsers for these languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "typescript",
        "tsx",
        "javascript",
        "python",
        "go",
        "gomod",
        "gosum",
        "lua",
        "bash",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
      })
    end,
  },
}
