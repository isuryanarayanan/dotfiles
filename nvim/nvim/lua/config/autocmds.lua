-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- :Hb opens the Neovim handbook
vim.api.nvim_create_user_command("Hb", function()
  local config_dir = vim.fn.stdpath("config")
  -- config_dir is the symlink target (nvim/nvim/), handbook is one level up (nvim/)
  local handbook = vim.fn.resolve(config_dir) .. "/../nvim-handbook.md"
  vim.cmd("edit " .. vim.fn.fnameescape(handbook))
end, { desc = "Open Neovim handbook" })
