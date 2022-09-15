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

return M
