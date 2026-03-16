-- netrw を無効化（nvim-tree と競合するため、早期に設定）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

-- 行番号
opt.number = true
opt.relativenumber = true

-- インデント
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- 検索
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- 表示
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.wrap = false

-- ファイル
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- クリップボード
opt.clipboard = "unnamedplus"
