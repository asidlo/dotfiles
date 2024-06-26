return {
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = true,
  },
  -- {
  --   "ray-x/go.nvim",
  --   dependencies = { -- optional packages
  --     "ray-x/guihua.lua",
  --     "neovim/nvim-lspconfig",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = function()
  --     require("go").setup()
  --   end,
  --   event = { "CmdlineEnter" },
  --   ft = { "go", "gomod" },
  --   build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  -- },
  {
    "tpope/vim-unimpaired",
    event = "BufRead",
  },
  {
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- https://github.com/neovim/nvim-lspconfig/issues/2810
        powershell_es = {
          init_options = { enableProfileLoading = false },
          settings = {
            powershell = {
              codeFormatting = {
                openBraceOnSameLine = false,
                whitespaceInsideBrace = true,
              },
            },
          },
        },
      },
    },
    -- setup = {
    --   powershell_es = function (_, opts)
    --     vim.tbl_extend('force', opts, init_options = { enableProfileLoading = false })
    --
    --   end
    -- }
  },
}
