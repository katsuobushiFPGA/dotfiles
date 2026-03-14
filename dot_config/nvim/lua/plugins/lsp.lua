return {
  -- LSP インストーラー
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason と lspconfig を橋渡し
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "intelephense", "ts_ls", "eslint" },
        automatic_installation = true,
      })
    end,
  },

  -- LSP 設定
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("intelephense", { capabilities = capabilities })
      vim.lsp.config("ts_ls",        { capabilities = capabilities })
      vim.lsp.config("eslint",       { capabilities = capabilities })
      vim.lsp.enable({ "intelephense", "ts_ls", "eslint" })

      -- LSP キーマップ
      vim.keymap.set("n", "gd",          vim.lsp.buf.definition,    { desc = "定義へ移動" })
      vim.keymap.set("n", "gr",          vim.lsp.buf.references,    { desc = "参照一覧" })
      vim.keymap.set("n", "K",           vim.lsp.buf.hover,         { desc = "ドキュメント表示" })
      vim.keymap.set("n", "<leader>rn",  vim.lsp.buf.rename,        { desc = "リネーム" })
      vim.keymap.set("n", "<leader>ca",  vim.lsp.buf.code_action,   { desc = "コードアクション" })
      vim.keymap.set("n", "<leader>e",   vim.diagnostic.open_float, { desc = "エラー詳細" })
      vim.keymap.set("n", "[d",          vim.diagnostic.goto_prev,  { desc = "前のエラー" })
      vim.keymap.set("n", "]d",          vim.diagnostic.goto_next,  { desc = "次のエラー" })
    end,
  },

  -- 自動補完
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"]   = cmp.mapping.complete(),
          ["<CR>"]    = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]   = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<C-e>"]   = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })
    end,
  },

  -- フォーマッター
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          php             = { "pint" },
          javascript      = { "prettier" },
          typescript      = { "prettier" },
          typescriptreact = { "prettier" },
          javascriptreact = { "prettier" },
          css             = { "prettier" },
          html            = { "prettier" },
          json            = { "prettier" },
        },
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
      })
    end,
  },
}
