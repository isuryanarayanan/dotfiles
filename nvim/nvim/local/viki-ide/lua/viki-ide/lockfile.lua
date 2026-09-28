local M = {}

local function lock_dir()
	local override = os.getenv("VIKI_IDE_LOCK_DIR")
	if override and override ~= "" then return vim.fn.expand(override) end
	return vim.fn.expand("~/.viki/ide")
end

M.lock_dir = lock_dir()
local CLAUDE_LOCK_DIR = vim.fn.expand("~/.claude/ide")

local function lock_dirs(opts)
	local dirs = { M.lock_dir }
	if opts and opts.claude_code_compat then
		table.insert(dirs, CLAUDE_LOCK_DIR)
	end
	return dirs
end

local function generate_auth_token()
	local file = io.open("/dev/urandom", "rb")
	if file then
		local bytes = file:read(32)
		file:close()
		if bytes and #bytes == 32 then
			return (bytes:gsub(".", function(byte) return string.format("%02x", string.byte(byte)) end))
		end
	end
	error("viki-ide requires a cryptographically secure /dev/urandom source")
end

M.generate_auth_token = generate_auth_token

local function get_lsp_clients()
	if vim.lsp and vim.lsp.get_clients then return vim.lsp.get_clients() end
	if vim.lsp and vim.lsp.get_active_clients then return vim.lsp.get_active_clients() end
	return {}
end

local function get_workspace_folders()
	local folders = { vim.fn.getcwd() }
	for _, client in pairs(get_lsp_clients()) do
		if client.config and client.config.workspace_folders then
			for _, ws in ipairs(client.config.workspace_folders) do
				local path = vim.uri_to_fname(ws.uri)
				local seen = false
				for _, f in ipairs(folders) do if f == path then seen = true break end end
				if not seen then folders[#folders + 1] = path end
			end
		end
	end
	return folders
end

function M.create(port, auth_token, opts)
	if type(port) ~= "number" or port < 1 or port > 65535 then
		return false, "Invalid port: " .. tostring(port)
	end
	auth_token = auth_token or generate_auth_token()
	local content = vim.json.encode({
		pid = vim.fn.getpid(),
		workspaceFolders = get_workspace_folders(),
		ideName = "Neovim",
		transport = "ws",
		authToken = auth_token,
	})

	local written = {}
	for _, dir in ipairs(lock_dirs(opts)) do
		vim.fn.mkdir(dir, "p")
		local path = dir .. "/" .. port .. ".lock"
		local fd, open_err = vim.loop.fs_open(path, "w", 384) -- create as 0600; never expose the token as 0644
		if not fd then
			for _, p in ipairs(written) do pcall(os.remove, p) end
			return false, "Failed to open lockfile: " .. path .. " (" .. tostring(open_err) .. ")"
		end
		local wrote, write_err = vim.loop.fs_write(fd, content, -1)
		vim.loop.fs_close(fd)
		if not wrote then
			pcall(os.remove, path)
			for _, p in ipairs(written) do pcall(os.remove, p) end
			return false, "Failed to write lockfile: " .. path .. " (" .. tostring(write_err) .. ")"
		end
		pcall(vim.loop.fs_chmod, path, 384)
		written[#written + 1] = path
	end
	return true, written[1], auth_token
end

function M.update_attached(port, attached)
	local path = M.lock_dir .. "/" .. port .. ".lock"
	local file = io.open(path, "r")
	if not file then return false end
	local raw = file:read("*a")
	file:close()
	local ok, data = pcall(vim.json.decode, raw)
	if not ok or type(data) ~= "table" then return false end
	data.attached = attached or vim.NIL
	local out = io.open(path, "w")
	if not out then return false end
	out:write(vim.json.encode(data))
	out:close()
	pcall(vim.loop.fs_chmod, path, 384)
	return true
end

function M.remove(port, opts)
	if type(port) ~= "number" then return false, "Invalid port" end
	for _, dir in ipairs(lock_dirs(opts)) do
		local path = dir .. "/" .. port .. ".lock"
		if vim.fn.filereadable(path) == 1 then
			pcall(os.remove, path)
		end
	end
	return true
end

return M
