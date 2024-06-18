return {
  {
    "echasnovski/mini.animate",
    opts = function(_, opts)
      opts.cursor = { enable = false }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if vim.loop.os_uname().sysname == "Windows_NT" then
        return vim.tbl_extend("force", opts, {
          install = { compilers = { "clang" } },
        })
      else
        return opts
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        gitcommit = { "gitlint" },
        text = { "vale" },
        markdown = { "vale", "markdownlint" },
        ["*"] = { "codespell" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "markdownlint", "cbfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        sh = { "shfmt" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "gitlint",
        "shellcheck",
        "codespell",
        "vale",
        "bicep-lsp",
        "cbfmt",
        "lemminx",
        "beautysh",
      })
    end,
  },
}
