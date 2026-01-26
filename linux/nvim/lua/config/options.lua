-- config/options.lua - Vim Options
local opt = vim.opt

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General settings
opt.mouse = "a"                     -- Enable mouse support
opt.clipboard = "unnamedplus"       -- Use system clipboard
opt.swapfile = false               -- No swap files
opt.backup = false                 -- No backup files
opt.undofile = true                -- Persistent undo
opt.updatetime = 250               -- Faster completion
opt.timeoutlen = 300               -- Faster key sequences

-- Session options (fix auto-session warning)
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- UI settings
opt.number = true                  -- Show line numbers
opt.relativenumber = true          -- Show relative line numbers
opt.signcolumn = "yes"             -- Always show sign column
opt.wrap = false                   -- Don't wrap lines
opt.scrolloff = 8                  -- Keep 8 lines visible when scrolling
opt.sidescrolloff = 8              -- Keep 8 columns visible when scrolling
opt.cursorline = true              -- Highlight current line
opt.termguicolors = true           -- True color support

-- Search settings
opt.ignorecase = true              -- Ignore case in search
opt.smartcase = true               -- Smart case matching
opt.hlsearch = false               -- Don't highlight search results
opt.incsearch = true               -- Incremental search

-- Indentation
opt.tabstop = 4                    -- Tab width
opt.softtabstop = 4                -- Soft tab width
opt.shiftwidth = 4                 -- Indent width
opt.expandtab = true               -- Use spaces instead of tabs
opt.smartindent = true             -- Smart indentation
opt.autoindent = true              -- Auto indentation

-- Splits
opt.splitbelow = true              -- Horizontal splits go below
opt.splitright = true              -- Vertical splits go right

-- File handling
opt.fileencoding = "utf-8"         -- File encoding
opt.conceallevel = 0               -- Don't conceal characters

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Performance
opt.lazyredraw = true              -- Don't redraw during macros