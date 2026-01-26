-- plugins/tools.lua - Development tools (terminal, sessions, etc.)
return {
  -- Terminal integration
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- Terminal keymaps
      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
      end

      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

      -- Custom terminal functions
      local Terminal = require("toggleterm.terminal").Terminal

      -- Python terminal
      local python = Terminal:new({
        cmd = "python3",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
        on_close = function(term)
          vim.cmd("startinsert!")
        end,
      })

      function _PYTHON_TOGGLE()
        python:toggle()
      end

      -- Node.js terminal
      local node = Terminal:new({
        cmd = "node",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
        on_close = function(term)
          vim.cmd("startinsert!")
        end,
      })

      function _NODE_TOGGLE()
        node:toggle()
      end

      -- Lazygit terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "none",
          width = 100000,
          height = 100000,
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
        on_close = function(term)
          vim.cmd("startinsert!")
        end,
      })

      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end

      -- Additional keymaps for custom terminals
      vim.keymap.set("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<CR>", { desc = "Toggle Python terminal" })
      vim.keymap.set("n", "<leader>tn", "<cmd>lua _NODE_TOGGLE()<CR>", { desc = "Toggle Node terminal" })
      vim.keymap.set("n", "<leader>tg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { desc = "Toggle LazyGit terminal" })
    end,
  },

  -- Session management
  {
    "rmagatti/auto-session",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "rmagatti/session-lens",
    },
    config = function()
      -- Safe wrapper to open nvim-tree after session restore
      local function safe_nvim_tree_open()
        vim.schedule(function()
          local ok, api = pcall(require, "nvim-tree.api")
          if ok and api and api.tree then
            pcall(api.tree.open)
          end
        end)
      end

      -- Safe wrapper to close nvim-tree before session save
      local function safe_nvim_tree_close()
        local ok, api = pcall(require, "nvim-tree.api")
        if ok and api and api.tree then
          pcall(api.tree.close)
        end
      end

      require("auto-session").setup({
        log_level = "error",
        enabled = true,
        auto_save = true,
        auto_restore = true,
        suppressed_dirs = { "~/", "~/Downloads", "/" },
        git_use_branch_name = true, -- Include git branch in session name (updated config name)
        
        -- Pre and post session commands (using safe wrappers)
        pre_save_cmds = { safe_nvim_tree_close },
        post_restore_cmds = { safe_nvim_tree_open },
      })

      -- Load telescope extension for session management
      pcall(require("telescope").load_extension, "session-lens")

      -- Session keymaps
      vim.keymap.set("n", "<leader>ss", function()
        require("telescope").extensions["session-lens"].search_session()
      end, {
        noremap = true,
        desc = "Search sessions",
      })
      vim.keymap.set("n", "<leader>sd", ":SessionDelete<CR>", { desc = "Delete session" })
      vim.keymap.set("n", "<leader>sr", ":SessionRestore<CR>", { desc = "Restore session" })
      vim.keymap.set("n", "<leader>sS", ":SessionSave<CR>", { desc = "Save session" })
    end,
  },

  -- Project management
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "lsp", "pattern" },
        patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "go.mod", "pyproject.toml" },
        ignore_lsp = {},
        exclude_dirs = {},
        show_hidden = false,
        silent_chdir = true,
        scope_chdir = "global",
        datapath = vim.fn.stdpath("data"),
      })

      -- Load telescope extension for projects
      require("telescope").load_extension("projects")

      -- Project keymaps
      vim.keymap.set("n", "<leader>fp", ":Telescope projects<CR>", { desc = "Find projects" })
    end,
  },

  -- Which-key (shows available keybindings)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
    config = function()
      local wk = require("which-key")
      wk.setup({
        preset = "modern",
        win = {
          border = "rounded",
          position = "bottom",
          margin = { 1, 0, 1, 0 },
          padding = { 2, 2, 2, 2 },
          winblend = 0,
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "left",
        },
      })

      -- Add key group descriptions
      wk.add({
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunk" },
        { "<leader>s", group = "session" },
        { "<leader>t", group = "terminal" },
        { "<leader>w", group = "workspace" },
        { "<leader>c", group = "copilot" },
        { "<leader>a", group = "ai" },
        { "<leader>d", group = "diff" },
        { "<leader>x", group = "trouble" },
      })
    end,
  },

  -- Trouble (better diagnostics list)
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        position = "bottom",
        height = 10,
        width = 50,
        icons = true,
        mode = "workspace_diagnostics",
        fold_open = "",
        fold_closed = "",
        group = true,
        padding = true,
        action_keys = {
          close = "q",
          cancel = "<esc>",
          refresh = "r",
          jump = { "<cr>", "<tab>" },
          open_split = { "<c-x>" },
          open_vsplit = { "<c-v>" },
          open_tab = { "<c-t>" },
          jump_close = { "o" },
          toggle_mode = "m",
          toggle_preview = "P",
          hover = "K",
          preview = "p",
          close_folds = { "zM", "zm" },
          open_folds = { "zR", "zr" },
          toggle_fold = { "zA", "za" },
          previous = "k",
          next = "j",
        },
        indent_lines = true,
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_fold = false,
        auto_jump = { "lsp_definitions" },
        signs = {
          error = "",
          warning = "",
          hint = "",
          information = "",
          other = "﫠",
        },
        use_diagnostic_signs = false,
      })

      -- Trouble keymaps
      vim.keymap.set("n", "<leader>xx", ":TroubleToggle<CR>", { desc = "Toggle trouble" })
      vim.keymap.set("n", "<leader>xw", ":TroubleToggle workspace_diagnostics<CR>", { desc = "Workspace diagnostics" })
      vim.keymap.set("n", "<leader>xd", ":TroubleToggle document_diagnostics<CR>", { desc = "Document diagnostics" })
      vim.keymap.set("n", "<leader>xl", ":TroubleToggle loclist<CR>", { desc = "Location list" })
      vim.keymap.set("n", "<leader>xq", ":TroubleToggle quickfix<CR>", { desc = "Quickfix list" })
      vim.keymap.set("n", "gR", ":TroubleToggle lsp_references<CR>", { desc = "LSP references" })
    end,
  },
}