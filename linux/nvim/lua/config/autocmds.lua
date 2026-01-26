-- config/autocmds.lua - Auto Commands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General settings
local general = augroup("General", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
  group = general,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Remove trailing whitespace
autocmd("BufWritePre", {
  group = general,
  pattern = "*",
  command = "%s/\\s\\+$//e",
})

-- Auto resize splits when window is resized
autocmd("VimResized", {
  group = general,
  pattern = "*",
  command = "tabdo wincmd =",
})

-- Don't auto comment new lines
autocmd("BufEnter", {
  group = general,
  pattern = "*",
  command = "set fo-=c fo-=r fo-=o",
})

-- Language specific settings
local filetypes = augroup("FileTypes", { clear = true })

-- Python settings
autocmd("FileType", {
  group = filetypes,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- JavaScript/TypeScript settings
autocmd("FileType", {
  group = filetypes,
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- Go settings
autocmd("FileType", {
  group = filetypes,
  pattern = "go",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false -- Go uses tabs
  end,
})

-- JSON settings
autocmd("FileType", {
  group = filetypes,
  pattern = "json",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- YAML settings
autocmd("FileType", {
  group = filetypes,
  pattern = "yaml",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- Custom commands
-- Ollama status check command
vim.api.nvim_create_user_command("OllamaStatus", function()
  local ollama = require("config.ollama")
  local config = ollama.setup()
  
  if config.accessible then
    local models = ollama.get_available_models(config.host, config.port)
    if #models > 0 then
      vim.notify("✅ Ollama is running\n📦 Available models: " .. table.concat(models, ", "), vim.log.levels.INFO)
    else
      vim.notify("✅ Ollama is running but no models found", vim.log.levels.WARN)
    end
  else
    vim.notify("❌ Ollama is not accessible from WSL2", vim.log.levels.ERROR)
  end
end, { desc = "Check Ollama connection status" })