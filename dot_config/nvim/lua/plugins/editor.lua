return {
  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
    },
  },

  -- シンタックスハイライト
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main  = "nvim-treesitter.configs",
    opts  = {
      ensure_installed = {
        "lua", "vim", "bash",
        "php", "typescript", "tsx", "javascript",
        "html", "css", "json", "yaml", "markdown",
      },
      highlight = { enable = true },
      indent    = { enable = true },
    },
  },
}
