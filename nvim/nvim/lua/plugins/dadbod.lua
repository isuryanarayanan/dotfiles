-- Database interaction: vim-dadbod (core engine), dadbod-ui (explorer sidebar),
-- and dadbod-completion (table/column names via blink.cmp).
-- Supports PostgreSQL, SQLite, and Redis.
-- Connection: set DATABASE_URL in your environment or .env / direnv.
-- Includes SQL execution from markdown fenced blocks, visual selection, and inline.
return {
  -- Core database engine + SQL execution from markdown
  {
    "tpope/vim-dadbod",
    cmd = "DB",
    ft = { "sql", "markdown", "zsh" },
    init = function()
      -- Read connection URL from environment
      vim.g.db = vim.env.DATABASE_URL or ""
    end,
    config = function()
      --- Get the SQL content of the fenced code block under the cursor.
      --- Returns nil if the cursor is not inside a ```sql block.
      ---@return string|nil
      local function get_sql_fenced_block()
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local block_start, block_end

        -- Search backwards for opening ```sql fence
        for i = cursor_line, 1, -1 do
          if lines[i]:match("^%s*```%s*$") or (lines[i]:match("^%s*```%w") and not lines[i]:match("^%s*```sql")) then
            return nil
          end
          if lines[i]:match("^%s*```sql") then
            block_start = i
            break
          end
        end
        if not block_start then
          return nil
        end

        -- Search forwards for closing ``` fence
        for i = cursor_line, #lines do
          if lines[i]:match("^%s*```%s*$") then
            block_end = i
            break
          end
        end
        if not block_end then
          return nil
        end

        local sql_lines = {}
        for i = block_start + 1, block_end - 1 do
          table.insert(sql_lines, lines[i])
        end
        local sql = vim.trim(table.concat(sql_lines, "\n"))
        return sql ~= "" and sql or nil
      end

      --- Check if dadbod has a usable connection URL
      ---@return boolean
      local function has_db_connection()
        local url = vim.g.db or ""
        if url ~= "" then
          return true
        end
        local buf_db = vim.b.db or ""
        if buf_db ~= "" then
          return true
        end
        local ok, conn = pcall(function()
          return vim.fn["db_ui#get_conn_url"]()
        end)
        if ok and conn and conn ~= "" then
          return true
        end
        return false
      end

      --- Execute a SQL string via dadbod
      ---@param sql string
      local function execute_sql(sql)
        if not sql or sql == "" then
          vim.notify("No SQL to execute", vim.log.levels.WARN)
          return
        end
        if not has_db_connection() then
          vim.notify("No database connection. Set DATABASE_URL or run :DBUIAddConnection", vim.log.levels.ERROR)
          return
        end
        vim.cmd("DB " .. sql)
      end

      local allowed_ft = { sql = true, markdown = true, zsh = true }

      -- Normal mode: execute fenced SQL block (markdown) or current paragraph (sql)
      vim.keymap.set("n", "<localleader>ww", function()
        if not allowed_ft[vim.bo.filetype] then
          return
        end
        if vim.bo.filetype == "markdown" then
          local sql = get_sql_fenced_block()
          if sql then
            execute_sql(sql)
          else
            vim.notify("Cursor is not inside a ```sql fenced block", vim.log.levels.WARN)
          end
        else
          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local start_line, end_line = cursor_line, cursor_line

          while start_line > 1 and vim.trim(lines[start_line - 1]) ~= "" do
            start_line = start_line - 1
          end
          while end_line < #lines and vim.trim(lines[end_line + 1]) ~= "" do
            end_line = end_line + 1
          end

          local sql_lines = {}
          for i = start_line, end_line do
            table.insert(sql_lines, lines[i])
          end
          execute_sql(vim.trim(table.concat(sql_lines, "\n")))
        end
      end, { silent = true, desc = "Execute SQL (block/paragraph)" })

      -- Visual mode: execute selected text as SQL
      vim.keymap.set("x", "<localleader>ww", function()
        if not allowed_ft[vim.bo.filetype] then
          return
        end
        local saved = vim.fn.getreg("z")
        vim.cmd('noautocmd normal! "zy')
        local sql = vim.trim(vim.fn.getreg("z"))
        vim.fn.setreg("z", saved)
        execute_sql(sql)
      end, { silent = true, desc = "Execute SQL selection" })

      -- Normal mode: execute current line as SQL
      vim.keymap.set("n", "<localleader>wl", function()
        if not allowed_ft[vim.bo.filetype] then
          return
        end
        local line = vim.trim(vim.api.nvim_get_current_line())
        if line == "" or line:match("^```") then
          vim.notify("Current line is empty or a fence marker", vim.log.levels.WARN)
          return
        end
        execute_sql(line)
      end, { silent = true, desc = "Execute SQL line" })
    end,
  },

  -- Database explorer UI
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1

      -- Use DATABASE_URL as the default connection when set
      if vim.env.DATABASE_URL and vim.env.DATABASE_URL ~= "" then
        vim.g.dbs = { { name = "default", url = vim.env.DATABASE_URL } }
      end
    end,
  },

  -- SQL completion via blink.cmp (complete_func source wrapping dadbod's omnifunc)
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = { "tpope/vim-dadbod" },
    ft = { "sql", "mysql", "plsql" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          vim.bo.omnifunc = "vim_dadbod_completion#omni"
        end,
      })
    end,
  },

  -- Register dadbod completion as a blink.cmp source
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "dadbod" },
        providers = {
          dadbod = {
            name = "Dadbod",
            module = "blink.cmp.sources.complete_func",
            enabled = function()
              return vim.bo.omnifunc == "vim_dadbod_completion#omni"
            end,
            opts = {
              complete_func = function()
                return "vim_dadbod_completion#omni"
              end,
            },
          },
        },
      },
    },
  },
}
