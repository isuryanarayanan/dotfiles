-- config/keymaps.lua - Key Mappings
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize windows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Buffer navigation
keymap("n", "<Tab>", ":bnext<CR>", opts)
keymap("n", "<S-Tab>", ":bprevious<CR>", opts)
keymap("n", "<leader>bd", ":bdelete<CR>", opts)

-- Better indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Clear search highlighting
keymap("n", "<leader>h", ":nohlsearch<CR>", opts)

-- Quick save and quit
keymap("n", "<leader>w", ":w<CR>", opts)
keymap("n", "<leader>q", ":q<CR>", opts)
keymap("n", "<leader>Q", ":qa!<CR>", opts)

-- File Explorer (will be mapped to nvim-tree)
-- Override the default Ctrl+w+w behavior to toggle nvim-tree
keymap("n", "<C-w><C-w>", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "Toggle nvim-tree" })
keymap("n", "<C-w>w", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "Toggle nvim-tree" })
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
keymap("n", "<leader>o", ":NvimTreeFocus<CR>", opts)
keymap("n", "<leader>E", ":NvimTreeFindFileToggle<CR>", opts)

-- Telescope (will be configured with telescope plugin)
keymap("n", "<leader>ff", ":Telescope find_files<CR>", opts)
keymap("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
keymap("n", "<leader>fb", ":Telescope buffers<CR>", opts)
keymap("n", "<leader>fh", ":Telescope help_tags<CR>", opts)
keymap("n", "<leader>fr", ":Telescope lsp_references<CR>", opts)
keymap("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", opts)

-- Git (will be configured with git plugins)
keymap("n", "<leader>gg", ":LazyGit<CR>", opts)

-- Terminal (will be configured with toggleterm)
keymap("n", "<leader>t", ":ToggleTerm<CR>", opts)

-- LSP (will be configured when LSP is attached)
-- These will be set up in the LSP configuration file

-- Sessions (will be configured with auto-session)
keymap("n", "<leader>ss", ":SearchSession<CR>", opts)