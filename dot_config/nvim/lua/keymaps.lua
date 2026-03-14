local map = vim.keymap.set

vim.g.mapleader = " "

-- ファイル保存 / 終了
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")

-- ウィンドウ分割移動
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- インデント後に選択を維持
map("v", "<", "<gv")
map("v", ">", ">gv")

-- 行移動（ビジュアルライン）
map("n", "j", "gj")
map("n", "k", "gk")
