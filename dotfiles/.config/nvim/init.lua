-- Basic Neovim configuration
-- This configuration provides essential settings for a modern development environment

-- Basic settings
vim.opt.number = true              -- Show line numbers
vim.opt.relativenumber = true      -- Show relative line numbers
vim.opt.expandtab = true           -- Use spaces instead of tabs
vim.opt.shiftwidth = 2             -- Set tab width to 2 spaces
vim.opt.tabstop = 2                -- Set tab stop to 2 spaces
vim.opt.softtabstop = 2            -- Set soft tab stop to 2 spaces
vim.opt.smartindent = true         -- Smart indentation
vim.opt.wrap = false               -- Don't wrap lines
vim.opt.ignorecase = true          -- Case insensitive searching
vim.opt.smartcase = true           -- Smart case searching (case sensitive if uppercase used)
vim.opt.hlsearch = false           -- Don't highlight search results
vim.opt.incsearch = true           -- Incremental search
vim.opt.termguicolors = true       -- Enable true color support
vim.opt.scrolloff = 8              -- Keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8          -- Keep 8 columns visible left/right of cursor
vim.opt.signcolumn = "yes"         -- Always show sign column
vim.opt.updatetime = 50            -- Faster completion
vim.opt.colorcolumn = "80"         -- Show column at 80 characters

-- Enable mouse support
vim.opt.mouse = "a"

-- Better split behavior
vim.opt.splitright = true          -- Vertical splits to the right
vim.opt.splitbelow = true          -- Horizontal splits below

-- Undo settings
vim.opt.undofile = true            -- Save undo history
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Leader key
vim.g.mapleader = " "              -- Set leader key to space

-- Key mappings
local keymap = vim.keymap.set

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

-- Stay in indent mode
keymap("v", "<", "<gv", { desc = "Stay in indent mode" })
keymap("v", ">", ">gv", { desc = "Stay in indent mode" })

-- Better paste
keymap("x", "p", '"_dP', { desc = "Paste without yanking" })

-- Clear search highlights
keymap("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- File explorer
keymap("n", "<leader>e", ":Ex<CR>", { desc = "Open file explorer" })

-- Quickfix list
keymap("n", "<leader>q", ":copen<CR>", { desc = "Open quickfix list" })
keymap("n", "<leader>Q", ":cclose<CR>", { desc = "Close quickfix list" })

-- Buffer navigation
keymap("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Window splits
keymap("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
keymap("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
keymap("n", "<leader>sc", ":close<CR>", { desc = "Close window" })

-- Terminal
keymap("n", "<leader>t", ":terminal<CR>", { desc = "Open terminal" })
keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Auto commands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("remove_trailing_whitespace", { clear = true }),
  pattern = "*",
  command = ":%s/\\s\\+$//e",
})

-- Auto-create directories when saving files
autocmd("BufWritePre", {
  group = augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Restore cursor position
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  pattern = "*",
  callback = function()
    local line = vim.fn.line("'\"")
    if line > 1 and line <= vim.fn.line("$") then
      vim.cmd('normal! g`"')
    end
  end,
})

print("Neovim configuration loaded successfully!")
