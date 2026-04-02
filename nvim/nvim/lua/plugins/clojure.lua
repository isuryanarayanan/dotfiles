-- Clojure development: REPL (Conjure), structural editing (paredit),
-- treesitter, and ANSI colorization for the log buffer.
-- LSP is handled by clojure-lsp (configured in lsp.lua, installed via mason).
-- Completion comes from clojure-lsp via blink.cmp (no extra config needed).
return {
  -- Treesitter: add clojure parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "clojure" } },
  },

  -- Structural editing for s-expressions
  {
    "julienvincent/nvim-paredit",
    ft = { "clojure" },
    opts = {},
  },

  -- ANSI color rendering in conjure log buffer
  {
    "m00qek/baleia.nvim",
    ft = { "clojure" },
    opts = { line_starts_at = 3 },
    config = function(_, opts)
      vim.g.conjure_baleia = require("baleia").setup(opts)

      vim.api.nvim_create_user_command("BaleiaColorize", function()
        vim.g.conjure_baleia.once(vim.api.nvim_get_current_buf())
      end, { bang = true })

      vim.api.nvim_create_user_command("BaleiaLogs", vim.g.conjure_baleia.logger.show, { bang = true })
    end,
  },

  -- Conjure: interactive REPL evaluation
  {
    "Olical/conjure",
    ft = { "clojure" },
    config = function(_, _)
      require("conjure.main").main()
      require("conjure.mapping")["on-filetype"]()
    end,
    init = function()
      -- Only activate conjure for clojure filetypes
      vim.g["conjure#filetypes"] = { "clojure" }

      -- Preserve ANSI escape sequences for baleia to colorize
      local has_baleia = pcall(require, "baleia")
      if has_baleia then
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 0
      else
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 1
      end

      -- Disable diagnostics in log buffer and apply colorization
      vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        pattern = "conjure-log-*",
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          vim.diagnostic.enable(false, { bufnr = buffer })

          if vim.g.conjure_baleia then
            vim.g.conjure_baleia.automatically(buffer)
          end

          -- Navigate between evaluation outputs in the log
          vim.keymap.set({ "n", "x" }, "[c", "<CMD>call search('^; -\\+$', 'bw')<CR>", {
            silent = true,
            buffer = true,
            desc = "Previous evaluation output",
          })
          vim.keymap.set({ "n", "x" }, "]c", "<CMD>call search('^; -\\+$', 'w')<CR>", {
            silent = true,
            buffer = true,
            desc = "Next evaluation output",
          })
        end,
      })

      -- Remap doc/def to <localleader>K and <localleader>gd
      -- so bare K and gd remain available for LSP
      vim.g["conjure#mapping#doc_word"] = "K"
      vim.g["conjure#mapping#def_word"] = "gd"
    end,
  },

}
