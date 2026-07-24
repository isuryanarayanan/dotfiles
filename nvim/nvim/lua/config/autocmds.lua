-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Force nowrap everywhere, overriding LazyVim's per-filetype wrap (lazyvim_wrap_spell)
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("force_nowrap", { clear = true }),
  callback = function()
    vim.opt_local.wrap = false
  end,
})

-- Opening a video file plays it in mpv (full framerate + audio).
-- Inside tmux it spawns a new tmux window running mpv; the neovim buffer just
-- shows a placeholder instead of loading the binary. Press q in that tmux
-- window to quit playback. Outside tmux, mpv is launched directly.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("video_playback", { clear = true }),
  pattern = { "*.mp4", "*.mov", "*.mkv", "*.webm", "*.avi", "*.m4v", "*.flv", "*.wmv" },
  callback = function(args)
    local file = vim.fn.expand("<afile>:p")
    -- Don't try to load binary bytes into the buffer.
    vim.bo[args.buf].buftype = "nofile"
    vim.bo[args.buf].bufhidden = "wipe"
    vim.bo[args.buf].modifiable = true
    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, { "▶ Playing in mpv: " .. file })
    vim.bo[args.buf].modifiable = false

    if vim.fn.executable("mpv") == 0 then
      vim.notify("mpv not found — install with `brew install mpv`", vim.log.levels.WARN)
      return
    end

    if vim.env.TMUX then
      vim.fn.jobstart(
        { "tmux", "new-window", "-n", "mpv", "mpv " .. vim.fn.shellescape(file) },
        { detach = true }
      )
    else
      vim.fn.jobstart({ "mpv", file }, { detach = true })
    end
  end,
})

-- :Hb opens the Neovim handbook
vim.api.nvim_create_user_command("Hb", function()
  local config_dir = vim.fn.stdpath("config")
  -- config_dir is the symlink target (nvim/nvim/), handbook is one level up (nvim/)
  local handbook = vim.fn.resolve(config_dir) .. "/../nvim-handbook.md"
  vim.cmd("edit " .. vim.fn.fnameescape(handbook))
end, { desc = "Open Neovim handbook" })
