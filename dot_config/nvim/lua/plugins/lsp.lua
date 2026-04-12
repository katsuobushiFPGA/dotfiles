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
        ensure_installed = {
          "intelephense",
          "eslint",
          "tailwindcss",
          "cssls",
          "html",
          "jsonls",
          "emmet_language_server",
        },
        automatic_installation = true,
      })
    end,
  },

  -- TypeScript LSP（ts_ls より高速・高機能）
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      settings = {
        expose_as_code_action = "all",
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
    keys = {
      { "<leader>ti", "<cmd>TSToolsAddMissingImports<cr>",    desc = "import を追加" },
      { "<leader>to", "<cmd>TSToolsOrganizeImports<cr>",      desc = "import を整理" },
      { "<leader>tu", "<cmd>TSToolsRemoveUnusedImports<cr>",  desc = "未使用 import を削除" },
    },
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
      local servers = { "intelephense", "eslint", "tailwindcss", "cssls", "html", "jsonls", "emmet_language_server" }

      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
      end
      vim.lsp.enable(servers)

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
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
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
          { name = "path" },
          { name = "buffer", keyword_length = 3 },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
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
          blade           = { "blade-formatter" },
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
