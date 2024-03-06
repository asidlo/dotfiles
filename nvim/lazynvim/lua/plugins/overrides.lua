return {
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.cursor = { enable = false }
    end,
  },
  {
    "williamboman/mason.nvim",

    opts = {
      ensure_installed = {
        "codespell",
        "bash-language-server",
        "shfmt",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        ["*"] = { "codespell" },
      },
    },
  },
}
