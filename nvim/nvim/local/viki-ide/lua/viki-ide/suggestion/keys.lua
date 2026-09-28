local M = {}

local DEFAULTS = {
	["<Plug>(VikiSuggest)"] = "<M-\\>",
	["<Plug>(VikiSuggestNext)"] = "<M-]>",
	["<Plug>(VikiSuggestPrev)"] = "<M-[>",
	["<Plug>(VikiSuggestDismiss)"] = "<C-]>",
}

function M.setup(actions, opts)
	opts = opts or {}
	local prior_tab = vim.fn.maparg("<Tab>", "i", false, true)
	local function plug(name, fn)
		vim.keymap.set("i", name, fn, { silent = true, desc = "viki-ide: " .. name })
	end
	plug("<Plug>(VikiSuggest)", actions.trigger)
	plug("<Plug>(VikiSuggestNext)", actions.cycle_next)
	plug("<Plug>(VikiSuggestPrev)", actions.cycle_prev)
	plug("<Plug>(VikiSuggestAccept)", actions.accept_all)
	plug("<Plug>(VikiSuggestAcceptLine)", actions.accept_line)
	plug("<Plug>(VikiSuggestAcceptWord)", actions.accept_word)
	plug("<Plug>(VikiSuggestDismiss)", actions.dismiss)
	if opts.default_keys == false then return end
	for lhs, rhs in pairs(DEFAULTS) do
		vim.keymap.set("i", rhs, lhs, { silent = true, remap = true })
	end
	vim.keymap.set("i", "<Tab>", function()
		if actions.has_active_suggestion() then
			-- Completion engines such as blink.cmp can invoke their fallback
			-- mappings while Neovim text is locked (E565). Accept on the next
			-- event-loop tick, after the completion callback has returned.
			vim.schedule(actions.accept_all)
			return ""
		end
		if type(opts.tab_fallback) == "function" then return opts.tab_fallback() or "" end
		if type(prior_tab) == "table" then
			if type(prior_tab.callback) == "function" then return prior_tab.callback() or "" end
			if type(prior_tab.rhs) == "string" and prior_tab.rhs ~= "" then return prior_tab.rhs end
		end
		return "\t"
	end, { expr = true, silent = true, replace_keycodes = true, desc = "viki-ide: accept suggestion or fall through" })
end

return M
