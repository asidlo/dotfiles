local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "markdown",
    "c_sharp"
  },
}

M.mason = {
  ensure_installed = {
    "lua-language-server",
    "stylua",
    "luacheck",
    "markdownlint",
    "prettierd",
    "shellcheck",
    "shellharden",
    "omnisharp"
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = false,
  },

  renderer = {
    highlight_git = false,
    icons = {
      show = {
        git = false,
      },
    },
  },
}

M.nvterm = {
  terminals = {
    type_opts = {
      float = {
        row = 0.1,
        col = 0.1,
        width = 0.8,
        height = 0.7,
      },
      horizontal = { location = "rightbelow", split_ratio = 0.3 },
      vertical = { location = "rightbelow", split_ratio = 0.5 },
    },
  },
}

return M
