local M = {}

local logger = require("viki-ide.logger")
local lockfile = require("viki-ide.lockfile")
local server = require("viki-ide.server.init")
local selection = require("viki-ide.selection")
local diff = require("viki-ide.diff")
local suggestion = require("viki-ide.suggestion")

M.state = { running = false, port = nil, lockfile_path = nil }
M.config = {}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "viki-ide" })
end

local function lockfile_opts()
	return {}
end

function M.setup(opts)
	opts = opts or {}
	M.config = opts
	logger.setup(opts)
	if opts.auto_start ~= false then
		vim.schedule(M.start)
	end
end

function M.start()
	if M.state.running then
		notify("viki-ide already running on port " .. M.state.port, vim.log.levels.WARN)
		return
	end
	local auth_token = lockfile.generate_auth_token()
	local ok, port_or_err = server.start({ auth_token = auth_token })
	if not ok then
		notify("Failed to start viki-ide server: " .. tostring(port_or_err), vim.log.levels.ERROR)
		return
	end
	local port = port_or_err
	local lock_ok, lock_path_or_err = lockfile.create(port, auth_token, lockfile_opts())
	if not lock_ok then
		server.stop()
		notify("Failed to write lockfile: " .. tostring(lock_path_or_err), vim.log.levels.ERROR)
		return
	end
	M.state.running = true
	M.state.port = port
	M.state.lockfile_path = lock_path_or_err
	selection.setup(server)
	suggestion.setup(server, M.config.suggestion or {})
end

function M.stop()
	if not M.state.running then return end
	selection.disable()
	suggestion.disable()
	diff.close_all()
	if M.state.port then lockfile.remove(M.state.port, lockfile_opts()) end
	server.stop()
	M.state.running = false
	M.state.port = nil
	M.state.lockfile_path = nil
	notify("viki-ide stopped")
end

function M.status()
	local s = server.get_status()
	local lines
	if not s.running then
		lines = { "viki-ide: not running" }
	else
		lines = {
			"viki-ide: running",
			"  port:     " .. s.port,
			"  clients:  " .. (s.client_count or 0),
			"  lockfile: " .. (M.state.lockfile_path or "-"),
		}
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	local width = 0
	for _, l in ipairs(lines) do
		local w = vim.fn.strdisplaywidth(l)
		if w > width then width = w end
	end
	width = math.max(width + 2, 32)
	local height = #lines
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " viki-ide status ",
		title_pos = "center",
	})
end

return M
