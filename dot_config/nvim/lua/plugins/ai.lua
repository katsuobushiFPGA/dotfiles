return {
  {
    "coder/claudecode.nvim",
    config = function()
      require("claudecode").setup()
    end,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>",       desc = "Claude Code を開く/閉じる" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",   mode = { "v" },  desc = "選択範囲を送信" },
    },
  },
}
