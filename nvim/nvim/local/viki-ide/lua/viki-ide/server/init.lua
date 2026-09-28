local M = {}

local logger = require("viki-ide.logger")
local tcp_server = require("viki-ide.server.tcp")
local tools = require("viki-ide.tools")
local diff = require("viki-ide.diff")
local lockfile = require("viki-ide.lockfile")
local completion_context = require("viki-ide.suggestion.context")

local MCP_PROTOCOL_VERSION = "2024-11-05"
local SERVER_NAME = "viki-ide-neovim"
local SERVER_VERSION = "0.1.0"

M.state = {
	server = nil,
	port = nil,
	ping_timer = nil,
	auth_token = nil,
	handlers = nil,
	outbound = {},
	next_outbound_id = 0,
	claim = nil,
}

local function register_handlers()
	M.state.handlers = {
		["initialize"] = function()
			return {
				protocolVersion = MCP_PROTOCOL_VERSION,
				capabilities = { logging = vim.empty_dict(), tools = { listChanged = true } },
				serverInfo = { name = SERVER_NAME, version = SERVER_VERSION },
			}
		end,
		["notifications/initialized"] = function() end,
		["tools/list"] = function() return { tools = tools.get_tool_list() } end,
		["tools/call"] = function(client, params)
			local r = tools.handle_invoke(client, params)
			if r and r._deferred then return r end
			if r.error then return nil, r.error end
			if r.result then return r.result, nil end
			return nil, { code = -32603, message = "Internal error", data = "Tool handler returned unexpected format" }
		end,
		["viki/claim"] = function(client, params)
			local current = M.state.claim
			if current and current.client_id ~= client.id then
				return nil, { code = -32001, message = "Neovim is already attached to another Pi process" }
			end
			M.state.claim = {
				client_id = client.id,
				pid = params.pid,
				sessionId = params.sessionId,
				sessionName = params.sessionName,
			}
			if M.state.port then lockfile.update_attached(M.state.port, M.state.claim) end
			vim.schedule(function() require("viki-ide.selection").send_current() end)
			return { claimed = true, protocolVersion = 1 }
		end,
		["viki/release"] = function(client)
			if M.state.claim and M.state.claim.client_id == client.id then
				M.state.claim = nil
				if M.state.port then lockfile.update_attached(M.state.port, nil) end
			end
			return { released = true }
		end,
		["viki/editorContext"] = function(client)
			if not M.state.claim or M.state.claim.client_id ~= client.id then
				return nil, { code = -32002, message = "Client has not claimed this editor" }
			end
			local bufnr = vim.api.nvim_get_current_buf()
			local cursor = vim.api.nvim_win_get_cursor(0)
			return completion_context.gather(bufnr, cursor[1] - 1, cursor[2], { manual = true })
		end,
	}
end

function M.start(opts)
	if M.state.server then return false, "Server already running" end

	M.state.auth_token = opts.auth_token
	register_handlers()

	local config = {
		host = "127.0.0.1",
		port_range = { min = 10000, max = 65535 },
	}
	local callbacks = {
		on_message = function(client, message) M._handle_message(client, message) end,
		on_connect = function(client)
			logger.debug("server", "client connected:", client.id)
		end,
		on_disconnect = function(client, code, reason)
			logger.debug("server", "client disconnected:", client.id, "(code:", code, ", reason:", reason or "N/A", ")")
			if M.state.claim and M.state.claim.client_id == client.id then
				M.state.claim = nil
				diff.close_all()
				if M.state.port then lockfile.update_attached(M.state.port, nil) end
			end
			for id, entry in pairs(M.state.outbound) do
				if entry.client_id == client.id then
					M.state.outbound[id] = nil
					vim.schedule(function()
						pcall(entry.callback, { code = -32000, message = "Client disconnected" }, nil)
					end)
				end
			end
		end,
		on_error = function(error_msg) logger.error("server", "server error:", error_msg) end,
	}

	local server, err = tcp_server.create_server(config, callbacks, M.state.auth_token)
	if not server then return false, err or "Unknown server creation error" end

	M.state.server = server
	M.state.port = server.port
	M.state.ping_timer = tcp_server.start_ping_timer(server, 30000)

	return true, server.port
end

function M.stop()
	if not M.state.server then return false, "Server not running" end
	if M.state.ping_timer then
		M.state.ping_timer:stop()
		M.state.ping_timer:close()
		M.state.ping_timer = nil
	end
	tcp_server.stop_server(M.state.server)
	_G.viki_ide_deferred_responses = {}
	for id, entry in pairs(M.state.outbound) do
		pcall(entry.callback, { code = -32000, message = "Server stopped" }, nil)
		M.state.outbound[id] = nil
	end
	M.state.server = nil
	M.state.port = nil
	M.state.auth_token = nil
	M.state.claim = nil
	return true
end

function M._handle_message(client, message)
	local ok, parsed = pcall(vim.json.decode, message)
	if not ok then
		M.send_response(client, nil, nil, { code = -32700, message = "Parse error", data = "Invalid JSON" })
		return
	end
	if type(parsed) ~= "table" or parsed.jsonrpc ~= "2.0" then
		M.send_response(client, parsed and parsed.id, nil, {
			code = -32600, message = "Invalid Request", data = "Not a valid JSON-RPC 2.0 message",
		})
		return
	end
	if parsed.id ~= nil and parsed.method == nil then
		M._handle_response(parsed)
		return
	end
	if parsed.id then M._handle_request(client, parsed) else M._handle_notification(client, parsed) end
end

function M._handle_response(response)
	local id = response.id
	local entry = M.state.outbound[id]
	if not entry then return end
	M.state.outbound[id] = nil
	if response.error then
		pcall(entry.callback, response.error, nil)
	else
		pcall(entry.callback, nil, response.result)
	end
end

function M._handle_request(client, request)
	local method = request.method
	local params = request.params or {}
	local id = request.id

	local handler = M.state.handlers[method]
	if not handler then
		M.send_response(client, id, nil, {
			code = -32601, message = "Method not found", data = "Unknown method: " .. tostring(method),
		})
		return
	end

	local success, result, error_data = pcall(handler, client, params)
	if success then
		if result and result._deferred then
			M._setup_deferred_response({
				client = result.client, id = id, coroutine = result.coroutine,
			})
			return
		end
		if error_data then
			M.send_response(client, id, nil, error_data)
		else
			M.send_response(client, id, result, nil)
		end
	else
		M.send_response(client, id, nil, { code = -32603, message = "Internal error", data = tostring(result) })
	end
end

function M._handle_notification(client, notification)
	local handler = M.state.handlers[notification.method]
	if handler then pcall(handler, client, notification.params or {}) end
end

function M._setup_deferred_response(info)
	local co = info.coroutine
	local response_sender = function(result)
		if result and result.content then
			M.send_response(info.client, info.id, result, nil)
		elseif result and result.error then
			M.send_response(info.client, info.id, nil, result.error)
		else
			M.send_response(info.client, info.id, nil, {
				code = -32603, message = "Internal error", data = "Deferred response had unexpected format",
			})
		end
	end
	_G.viki_ide_deferred_responses = _G.viki_ide_deferred_responses or {}
	_G.viki_ide_deferred_responses[tostring(co)] = response_sender
end

function M.send_response(client, id, result, error_data)
	if not M.state.server then return false end
	local response = { jsonrpc = "2.0", id = id }
	if error_data then response.error = error_data else response.result = result end
	tcp_server.send_to_client(M.state.server, client.id, vim.json.encode(response))
	return true
end

---Send a JSON-RPC notification to a single client (no id).
---@param client WebSocketClient The target client
---@param method string Method name
---@param params table|nil Parameters
---@return boolean success
function M.send_notification(client, method, params)
	if not M.state.server then return false end
	local message = { jsonrpc = "2.0", method = method, params = params or vim.empty_dict() }
	tcp_server.send_to_client(M.state.server, client.id, vim.json.encode(message))
	return true
end

function M.broadcast(method, params)
	if not M.state.server then return false end
	local message = { jsonrpc = "2.0", method = method, params = params or vim.empty_dict() }
	tcp_server.broadcast(M.state.server, vim.json.encode(message))
	return true
end

function M.first_client()
	if not M.state.server or not M.state.claim then return nil end
	local client = M.state.server.clients[M.state.claim.client_id]
	if client and client.state == "connected" then return client end
	return nil
end

function M.request_client(client, method, params, callback)
	if not M.state.server then
		callback({ code = -32000, message = "Server not running" }, nil)
		return nil
	end
	if not client then
		callback({ code = -32000, message = "No connected client" }, nil)
		return nil
	end
	M.state.next_outbound_id = M.state.next_outbound_id + 1
	local id = "out_" .. tostring(M.state.next_outbound_id)
	M.state.outbound[id] = { callback = callback, client_id = client.id }
	local payload = vim.json.encode({
		jsonrpc = "2.0",
		id = id,
		method = method,
		params = params or vim.empty_dict(),
	})
	tcp_server.send_to_client(M.state.server, client.id, payload, function(err)
		if err and M.state.outbound[id] then
			M.state.outbound[id] = nil
			vim.schedule(function() pcall(callback, { code = -32000, message = "Send failed: " .. tostring(err) }, nil) end)
		end
	end)
	return id
end

function M.cancel_request(id)
	local entry = M.state.outbound[id]
	if not entry then return end
	M.state.outbound[id] = nil
	if M.state.server then
		local client = M.state.server.clients[entry.client_id]
		if client then
			local msg = { jsonrpc = "2.0", method = "request_cancelled", params = { id = id } }
			tcp_server.send_to_client(M.state.server, client.id, vim.json.encode(msg))
		end
	end
	pcall(entry.callback, { code = -32800, message = "Request cancelled" }, nil)
end

function M.get_status()
	if not M.state.server then return { running = false } end
	return {
		running = true,
		port = M.state.port,
		client_count = tcp_server.get_client_count(M.state.server),
	}
end

return M
