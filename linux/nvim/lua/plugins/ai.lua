-- plugins/ai.lua - AI assistant plugins
return {
    -- GitHub Copilot
    {
        "github/copilot.vim",
        config = function()
            -- Copilot settings
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_assume_mapped = true

            -- Enable Copilot for specific filetypes (markdown is disabled by default)
            vim.g.copilot_filetypes = {
                ["*"] = true,
                ["markdown"] = true,
                ["md"] = true,
            }

            -- Custom keymaps for Copilot
            local keymap = vim.keymap.set
            -- Tab to accept suggestion (falls back to normal tab if no suggestion)
            keymap("i", "<Tab>", 'copilot#Accept("<Tab>")', { expr = true, replace_keycodes = false, silent = true })
            keymap("i", "<C-J>", 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false })
            keymap("i", "<C-K>", "copilot#Previous()", { expr = true, silent = true })
            keymap("i", "<C-L>", "copilot#Next()", { expr = true, silent = true })
            keymap("i", "<C-H>", "copilot#Dismiss()", { expr = true, silent = true })
        end,
    }


}

