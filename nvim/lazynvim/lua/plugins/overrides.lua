return {
  {
    "echasnovski/mini.animate",
    opts = function(_, opts)
      opts.cursor = { enable = false }
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
        "bicep-lsp",
      },
    },
  },
}
