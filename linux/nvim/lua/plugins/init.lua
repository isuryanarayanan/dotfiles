-- plugins/init.lua - Main plugin specifications
return {
  -- Essential plugins that will be configured in separate files
  { import = "plugins.ui" },          -- UI enhancements (theme, statusline, etc.)
  { import = "plugins.editor" },      -- Editor enhancements (file explorer, fuzzy finder)
  { import = "plugins.lsp" },         -- LSP and completion
  { import = "plugins.ai" },          -- AI assistants
  { import = "plugins.git" },         -- Git integration
  { import = "plugins.tools" },       -- Development tools (terminal, sessions)
}