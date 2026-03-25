-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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

    -- File paths → decode percent-encoding (%20 → space, etc.),
    -- then resolve relative to the buffer's directory.
    local path = url:gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    if not path:match("^/") then
      path = vim.fn.expand("%:p:h") .. "/" .. path
    end
    path = vim.fn.resolve(path)

    if vim.fn.filereadable(path) == 1 then
      vim.cmd.edit(path)
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
