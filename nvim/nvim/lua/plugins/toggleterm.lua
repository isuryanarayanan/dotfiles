-- Multiple persistent terminals with numbered access, split/float layouts,
-- and send-to-terminal for REPL workflows alongside Conjure.
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    -- Toggle the most recent terminal (or terminal #1)
    { [[<C-\>]], "<CMD>ToggleTerm<CR>", desc = "Toggle terminal" },
    -- Numbered terminals: <leader>t1, <leader>t2, <leader>t3
    {
      "<leader>t1",
      "<CMD>1ToggleTerm<CR>",
      desc = "Terminal #1",
    },
    {
      "<leader>t2",
      "<CMD>2ToggleTerm<CR>",
      desc = "Terminal #2",
    },
    {
      "<leader>t3",
      "<CMD>3ToggleTerm<CR>",
      desc = "Terminal #3",
    },
    -- Float / horizontal / vertical toggles
    {
      "<leader>tf",
      "<CMD>ToggleTerm direction=float<CR>",
      desc = "Terminal (float)",
    },
    {
      "<leader>th",
      "<CMD>ToggleTerm direction=horizontal<CR>",
      desc = "Terminal (horizontal)",
    },
    {
      "<leader>tv",
      "<CMD>ToggleTerm direction=vertical<CR>",
      desc = "Terminal (vertical)",
    },
    -- Send visual selection to terminal (useful for sending forms to a REPL)
    {
      "<leader>ts",
      "<CMD>ToggleTermSendVisualSelection<CR>",
      mode = "v",
      desc = "Send selection to terminal",
    },
  },
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    open_mapping = false, -- we handle mappings via keys above
    direction = "float",
    float_opts = {
      border = "curved",
    },
    -- Terminal-mode keymaps (set per-buffer so they only apply in toggleterm)
    on_open = function(term)
      local buf_opts = { buffer = term.bufnr, silent = true }

      -- Escape terminal mode with ESC ESC (double-tap to avoid conflicts)
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], vim.tbl_extend("force", buf_opts, {
        desc = "Exit terminal mode",
      }))

      -- Tmux-style navigation: exit terminal mode then navigate
      vim.keymap.set("t", "<C-h>", [[<C-\><C-n><CMD>TmuxNavigateLeft<CR>]], vim.tbl_extend("force", buf_opts, {
        desc = "Navigate left",
      }))
      vim.keymap.set("t", "<C-j>", [[<C-\><C-n><CMD>TmuxNavigateDown<CR>]], vim.tbl_extend("force", buf_opts, {
        desc = "Navigate down",
      }))
      vim.keymap.set("t", "<C-k>", [[<C-\><C-n><CMD>TmuxNavigateUp<CR>]], vim.tbl_extend("force", buf_opts, {
        desc = "Navigate up",
      }))
      vim.keymap.set("t", "<C-l>", [[<C-\><C-n><CMD>TmuxNavigateRight<CR>]], vim.tbl_extend("force", buf_opts, {
        desc = "Navigate right",
      }))
    end,
  },
}
