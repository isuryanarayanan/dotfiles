local function yank_file_ref()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end

  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(filepath, ":h")) .. " rev-parse --show-toplevel")[1]
  local ref
  if vim.v.shell_error ~= 0 or not git_root then
    ref = "@" .. filepath
  else
    local repo_name = vim.fn.fnamemodify(git_root, ":t")
    local rel = filepath:sub(#git_root + 2)
    ref = "@" .. repo_name .. "/" .. rel
  end

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then start_line, end_line = end_line, start_line end
    if start_line == end_line then
      ref = ref .. "#L" .. start_line
    else
      ref = ref .. "#L" .. start_line .. "-" .. end_line
    end
  else
    ref = ref .. "#L" .. vim.fn.line(".")
  end

  vim.fn.setreg("+", ref)
  vim.fn.setreg('"', ref)
  vim.notify("Yanked: " .. ref, vim.log.levels.INFO)
end

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- Claude detects $TMUX and wraps its OSC 52 clipboard writes in tmux
      -- passthrough escapes. But here Claude runs inside Neovim's :terminal
      -- (which is itself inside tmux), and Neovim's terminal can't parse the
      -- tmux wrapper, so it dumps the raw `52;c;...` bytes as text. Clearing
      -- TMUX makes Claude emit plain OSC 52, which Neovim handles and routes
      -- to the macOS clipboard via pbcopy.
      env = {
        TMUX = "",
        TMUX_PANE = "",
      },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "v" }, desc = "Send selection to Claude Code" },
      { "<leader>ay", yank_file_ref, mode = { "n", "v" }, desc = "Yank file ref (@repo/path#Lline)" },
    },
  },
}
