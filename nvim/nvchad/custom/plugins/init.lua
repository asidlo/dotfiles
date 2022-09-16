local overrides = require "custom.plugins.overrides"

return {
  -- Override plugin definition options
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.plugins.lspconfig"
    end,
  },

  ['nvim-telescope/telescope.nvim'] = {
    override_options = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
              ['<C-?>'] = actions.which_key,
              ['<esc>'] = actions.close,
            }
          },
        }
      }
    end
  },

  ['hrsh7th/nvim-cmp'] = {
    override_options = function()
      local cmp = require('cmp')
      return {
        mapping = {
          ['<CR>'] = cmp.mapping.confirm({ select = true })
        },
        experimental = {
          ghost_text = true,
          native_menu = false,
        }
      }
    end
  },

  -- overrde plugin configs
  ["nvim-treesitter/nvim-treesitter"] = {
    override_options = overrides.treesitter,
  },

  ["williamboman/mason.nvim"] = {
    override_options = overrides.mason,
  },

  ['NvChad/nvterm'] = {
    override_options = overrides.nvterm
  },

  ["kyazdani42/nvim-tree.lua"] = {
    override_options = overrides.nvimtree,
  },

  ["folke/which-key.nvim"] = {
    disable = false,
  },

  -- Install a plugin
  -- code formatting, linting etc
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require "custom.plugins.null-ls"
    end,
  },

  ['Hoffs/omnisharp-extended-lsp.nvim'] = {
    event = "BufRead"
  },

  ['ahmedkhalf/project.nvim'] = {
    event = "BufRead",
    config = function()
      require('custom.plugins.project')
    end
  }
}
