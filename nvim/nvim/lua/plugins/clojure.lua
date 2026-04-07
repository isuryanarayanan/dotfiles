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
    ft = { "clojure", "markdown" },
    config = function(_, _)
      require("conjure.main").main()
      require("conjure.mapping")["on-filetype"]()
    end,
    init = function()
      vim.g["conjure#filetypes"] = { "clojure", "markdown" }
      vim.g["conjure#filetype#markdown"] = "conjure.client.clojure.nrepl"
      vim.g["conjure#client_on_load"] = false

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

      local function connect_from_nrepl_port_file()
        local current_file = vim.api.nvim_buf_get_name(0)
        local start_path = current_file ~= "" and vim.fs.dirname(current_file) or vim.uv.cwd()
        local cwd = vim.uv.cwd()
        local git_marker = vim.fs.find(".git", { path = start_path, upward = true })[1]
        local git_root = git_marker and vim.fs.dirname(git_marker) or nil

        local candidates = {}
        if git_root then
          table.insert(candidates, git_root .. "/apps/api/.nrepl-port")
        end

        local nearest_from_file = vim.fs.find(".nrepl-port", { path = start_path, upward = true })[1]
        local nearest_from_cwd = vim.fs.find(".nrepl-port", { path = cwd, upward = true })[1]

        if nearest_from_file then
          table.insert(candidates, nearest_from_file)
        end
        if nearest_from_cwd and nearest_from_cwd ~= nearest_from_file then
          table.insert(candidates, nearest_from_cwd)
        end

        for _, port_file in ipairs(candidates) do
          if vim.uv.fs_stat(port_file) then
            local lines = vim.fn.readfile(port_file, "", 1)
            local port = lines[1] and vim.trim(lines[1]) or ""
            if port ~= "" then
              vim.cmd({ cmd = "ConjureConnect", args = { port } })
              vim.notify(("ConjureConnect %s (%s)"):format(port, port_file), vim.log.levels.INFO)
              return
            end
          end
        end

        vim.notify("No usable .nrepl-port found. Run lein repl or :ConjureConnect <port>", vim.log.levels.WARN)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "clojure", "edn", "markdown" },
        callback = function(event)
          vim.keymap.set("n", "<localleader>cc", function()
            local ok, mapping = pcall(require, "conjure.mapping")
            if ok then
              mapping["on-filetype"]()
            end

            connect_from_nrepl_port_file()
          end, {
            buffer = event.buf,
            silent = true,
            desc = "Conjure connect from .nrepl-port",
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.keymap.set("n", "<localleader>ce", function()
            local ok, mapping = pcall(require, "conjure.mapping")
            if ok then
              mapping["on-filetype"]()
            end

            local line = vim.api.nvim_get_current_line()
            local expression = vim.trim(line)
            if expression == "" or expression:match("^```") then
              return
            end

            vim.cmd({ cmd = "ConjureEval", args = { expression } })
          end, {
            buffer = event.buf,
            silent = true,
            desc = "Conjure eval expression",
          })

          vim.keymap.set("x", "<localleader>ce", function()
            local ok, mapping = pcall(require, "conjure.mapping")
            if ok then
              mapping["on-filetype"]()
            end

            vim.cmd("'<,'>ConjureEval")
          end, {
            buffer = event.buf,
            silent = true,
            desc = "Conjure eval selection",
          })
        end,
      })
    end,
  },

}
