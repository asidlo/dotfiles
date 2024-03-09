return {
  {
    "echasnovski/mini.animate",
    opts = function(_, opts)
      opts.cursor = { enable = false }
    end,
  },
  {
    "nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, 1, {
        name = "copilot",
        group_index = 1,
        priority = 1,
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        gitcommit = { "gitlint" },
        text = { "vale" },
        markdown = { "markdownlint", "vale" },
        ["*"] = { "codespell" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "gitlint",
        "eslint-lsp",
        "shellcheck",
        "codespell",
        "markdownlint",
        "vale",
      },
    },
  },
}
