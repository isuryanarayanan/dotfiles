-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function decode_url_component(value)
  return value:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
end

local function slugify_heading(text)
  local slug = text:lower()
  slug = slug:gsub("%s*#+%s*$", "")
  slug = slug:gsub("`", "")
  slug = slug:gsub("[^%w%s%-]", "")
  slug = slug:gsub("%s+", "-")
  slug = slug:gsub("%-+", "-")
  slug = slug:gsub("^%-", "")
  slug = slug:gsub("%-$", "")
  return slug
end

local function jump_to_markdown_anchor(bufnr, anchor)
  local target = anchor:gsub("^#", ""):lower()
  if target == "" then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local heading_text = line:match("^%s*#+%s+(.+)$")
    if heading_text and slugify_heading(heading_text) == target then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return true
    end

    local explicit_id = line:match("{#([^}]+)}")
    if explicit_id and explicit_id:lower() == target then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return true
    end
  end

  return false
end

-- ── gx: follow Markdown links ───────────────────────────────
-- Files: open as a Neovim buffer (resolved relative to the
--        current buffer's directory).
-- URIs:  open with the system handler (browser, etc.).
vim.keymap.set("n", "gx", function()
  for _, url in ipairs(require("vim.ui")._get_urls()) do
    -- URIs (https://, http://, etc.) → system handler
    if url:match("%w+:") then
      vim.ui.open(url)
      return
    end

    -- File paths → decode percent-encoding (%20 → space, etc.).
    local decoded = decode_url_component(url)

    -- Dual behavior: open file links; jump to markdown anchors.
    local path, fragment = decoded:match("^([^#]*)#?(.*)$")
    if path == "" then
      if not jump_to_markdown_anchor(0, fragment) then
        vim.notify("No such reference in current file: #" .. fragment, vim.log.levels.WARN)
      end
      return
    end

    -- Resolve relative to the current buffer's directory.
    if not path:match("^/") then
      path = vim.fn.expand("%:p:h") .. "/" .. path
    end
    path = vim.fn.resolve(path)

    if vim.fn.filereadable(path) == 1 then
      vim.cmd.edit(path)
      if fragment ~= "" then
        if not jump_to_markdown_anchor(0, fragment) then
          vim.notify("No such reference in file: #" .. fragment, vim.log.levels.WARN)
        end
      end
    elseif vim.fn.isdirectory(path) == 1 then
      vim.cmd.edit(path)
    else
      vim.ui.select({ "Yes", "No" }, { prompt = "Create " .. path .. "?" }, function(choice)
        if choice == "Yes" then
          local dir = vim.fn.fnamemodify(path, ":h")
          if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
          end
          vim.cmd.edit(path)
        end
      end)
    end
    return
  end
end, { desc = "Follow link under cursor" })

-- ── leader fa: find all files (including gitignored) ────────
vim.keymap.set("n", "<leader>fa", function()
  Snacks.picker.files({ ignored = true, hidden = true })
end, { desc = "Find All Files (incl. gitignored)" })
