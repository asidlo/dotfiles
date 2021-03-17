local packer = require('packer')

function _G.gitgutter_inner_pending()
  return replace_termcodes('<Plug>(GitGutterTextObjectInnerPending)')
end
function _G.gitgutter_outer_pending()
  return replace_termcodes('<Plug>(GitGutterTextObjectOuterPending)')
end
function _G.gitgutter_inner_visual()
  return replace_termcodes('<Plug>(GitGutterTextObjectInnerVisual)')
end
function _G.gitgutter_outer_visual()
  return replace_termcodes('<Plug>(GitGutterTextObjectOuterVisual)')
end

packer.init {
  display = {
    open_cmd = 'topleft 55vnew [packer]', -- An optional command to open a window for packer's display
  }
}

return packer.startup(function(use)
  use { 'wbthomason/packer.nvim', opt = true }
  use { 'dracula/vim', as = 'dracula' }
  use {
    'kyazdani42/nvim-tree.lua',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function ()
      vim.api.nvim_set_keymap("n", "<C-n>", '<Cmd>NvimTreeToggle<CR>', {noremap = true})
      vim.g.nvim_tree_width_allow_resize = 1
    end
  }
  use {
    'glepnir/galaxyline.nvim',
      branch = 'main',
      config = "require('config.galaxyline')",
      requires = {'kyazdani42/nvim-web-devicons', opt = true}
  }
  use {
    'neovim/nvim-lspconfig',
    config = "require('config.lsp')",
    requires = { 'nvim-lua/lsp_extensions.nvim' }
  }
  use {
    'glepnir/lspsaga.nvim',
    config = "require('config.lspsaga')"
  }
  use {
    'liuchengxu/vista.vim',
  }
  use {
    'hrsh7th/nvim-compe',
    config = "require('config.nvim-compe')",
  }
  use { 'norcalli/snippets.nvim' }
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = "require('config.treesitter')"
  }
  use { 'nvim-treesitter/nvim-treesitter-textobjects' }
  use {
    'tpope/vim-fugitive',
    config = function()
      vim.api.nvim_set_keymap('n', '<Leader>gs', '<Cmd>G status -s<CR>', { noremap = true })
      vim.api.nvim_set_keymap('n', '<Leader>gl', '<Cmd>G log --oneline<CR>', { noremap = true })
      vim.api.nvim_set_keymap('n', '<Leader>gb', '<Cmd>!git branch -a<CR>', { noremap = true })
      vim.api.nvim_set_keymap('n', '<Leader>gd', '<Cmd>G diff<CR>', { noremap = true })
    end,
  }
  use { 'tpope/vim-commentary' }
  use { 'tpope/vim-unimpaired' }
  use { 'tpope/vim-repeat' }
  use { 'tpope/vim-surround' }
  use { 'tpope/vim-dispatch' }
  use { 'tpope/vim-obsession' }
  use { 'airblade/vim-rooter' }
  use {
    'airblade/vim-gitgutter',
    config = function()
      -- Note: the <Plug> mappings are found in after/plugin/gitgutter.vim
      vim.g.gitgutter_map_keys = 0
      vim.api.nvim_set_keymap('n', ']h', '<Cmd>GitGutterNextHunk<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '[h', '<Cmd>GitGutterPrevHunk<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>hs', '<Cmd>GitGutterStageHunk<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>hu', '<Cmd>GitGutterUndoHunk<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>hp', '<Cmd>GitGutterPreviewHunk<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('o', 'ih', 'v:lua.gitgutter_inner_pending()', {expr = true})
      vim.api.nvim_set_keymap('o', 'ah', 'v:lua.gitgutter_outer_pending()', {expr = true})
      vim.api.nvim_set_keymap('x', 'ih', 'v:lua.gitgutter_inner_visual()', {expr = true})
      vim.api.nvim_set_keymap('x', 'ah', 'v:lua.gitgutter_outer_visual()', {expr = true})
    end,
  }
  use { 'rhysd/git-messenger.vim' }
  use { 'vim-scripts/ReplaceWithRegister' }

  -- Follow symlinks
  use { 'moll/vim-bbye' }
  use { 'aymericbeaumet/vim-symlink' }
  use { 'sheerun/vim-polyglot' }
  use {
    'plasticboy/vim-markdown',
    config = function()
      vim.g.vim_markdown_folding_style_pythonic = 1
      vim.g.vim_markdown_override_foldtext = 0

      -- Dont insert indent when using 'o' & dont auto insert bullets on format
      vim.g.vim_markdown_new_list_item_indent = 0
      vim.g.vim_markdown_auto_insert_bullets = 0
    end,
    requires = { 'godlygeek/tabular' }
  }
  -- use { 'wincent/ferret' }
  use {
    'nvim-telescope/telescope.nvim',
    requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}},
    config = "require('config.telescope')"
  }
  use {
    'RishabhRD/nvim-lsputils',
    requires = { 'RishabhRD/popfix' }
  }
  use {
    'junegunn/fzf.vim',
    requires = { 'junegunn/fzf'},
    config = function()
      vim.api.nvim_set_keymap('n', '<Leader>F', '<Cmd>Files<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>f', '<Cmd>GFiles<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>b', '<Cmd>Buffers<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>e', '<Cmd>History<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>x', '<Cmd>Maps<CR>', {noremap = true, silent = true})
      vim.api.nvim_set_keymap('n', '<Leader>X', '<Cmd>Commands<CR>', {noremap = true, silent = true})

      -- Dracula adds the CursorLine highlight to fzf
      vim.g.fzf_colors = {
        fg = { 'fg', 'Normal' },
        bg = { 'bg', 'Normal' },
        hl = { 'fg', 'Comment' },
        ['fg+'] = { 'fg', 'CursorLine', 'CursorColumn', 'Normal' },
        ['hl+'] = { 'fg', 'Statement' },
        info = { 'fg', 'PreProc' },
        border = { 'fg', 'Ignore' },
        prompt = { 'fg', 'Conditional' },
        pointer = { 'fg', 'Exception' },
        marker = { 'fg', 'Keyword' },
        spinner = { 'fg', 'Label' },
        header = { 'fg', 'Comment' }
      }
    end,
  }
  use {
    'mcchrish/nnn.vim',
    config = function()
      vim.g['nnn#layout'] = { window = { width = 0.9, height = 0.6 } }
    end
  }
end)
