-- general
lvim.log.level = 'warn'
lvim.format_on_save = true
lvim.colorscheme = 'tokyonight'

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = 'space'
lvim.keys.normal_mode['<C-s>'] = ':w<cr>'
lvim.keys.insert_mode['<C-s>'] = '<Esc>:w<cr>'
lvim.keys.normal_mode['[<Space>'] = [[maO<Esc>`a]]
lvim.keys.normal_mode[']<Space>'] = [[mao<Esc>`a]]
lvim.keys.normal_mode['<F5>'] = '<Cmd>mode<cr>'

lvim.keys.normal_mode['<S-l>'] = nil
lvim.keys.normal_mode['<S-h>'] = nil
lvim.keys.normal_mode[']b'] = '<Cmd>BufferNext<cr>'
lvim.keys.normal_mode['[b'] = '<Cmd>BufferPrevious<cr>'

--LuaFormatter off
-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
lvim.builtin.telescope.on_config_done = function()
  local actions = require 'telescope.actions'
  -- for input mode
  lvim.builtin.telescope.defaults.mappings.i['<C-j>'] = actions.move_selection_next
  lvim.builtin.telescope.defaults.mappings.i['<C-k>'] = actions.move_selection_previous
  lvim.builtin.telescope.defaults.mappings.i['<C-n>'] = actions.cycle_history_next
  lvim.builtin.telescope.defaults.mappings.i['<C-p>'] = actions.cycle_history_prev
  -- for normal mode
  lvim.builtin.telescope.defaults.mappings.n['<C-j>'] = actions.move_selection_next
  lvim.builtin.telescope.defaults.mappings.n['<C-k>'] = actions.move_selection_previous
end
--LuaFormatter on

local cmp = require('cmp')
lvim.builtin.cmp.mapping["<CR>"].invoke = cmp.mapping.confirm({select = true})

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings['P'] = {
  '<cmd>Telescope projects<CR>', 'Projects'
}
lvim.builtin.which_key.mappings['t'] = {
  name = '+Trouble',
  r = {'<cmd>Trouble lsp_references<cr>', 'References'},
  f = {'<cmd>Trouble lsp_definitions<cr>', 'Definitions'},
  d = {'<cmd>Trouble lsp_document_diagnostics<cr>', 'Diagnostics'},
  q = {'<cmd>Trouble quickfix<cr>', 'QuickFix'},
  l = {'<cmd>Trouble loclist<cr>', 'LocationList'},
  w = {'<cmd>Trouble lsp_workspace_diagnostics<cr>', 'Diagnostics'},
  t = {'<cmd>TroubleToggle<cr>', 'Toggle Trouble'},
  R = {'<cmd>TroubleRefresh<cr>', 'Refresh Trouble'}
}
lvim.builtin.which_key.mappings['S'] = {
  name = '+Session',
  l = {'<Cmd>lua require("persistence").load({last=true})<cr>', 'Load last session'},
  c = {'<Cmd>lua require("persistence").load()<cr>', 'Load current session'},
  s = {'<Cmd>lua require("persistence").stop()<cr>', 'Stop current session'},
}

-- User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.dap.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = 'left'
lvim.builtin.nvimtree.show_icons.tree_width = 40
lvim.builtin.nvimtree.show_icons.git = 0
lvim.builtin.nvimtree.setup.view.auto_resize = false
lvim.builtin.nvimtree.setup.view.nvim_tree_group_empty = 1
lvim.builtin.nvimtree.nvim_tree_gitignore = 1
lvim.builtin.nvimtree.ignore = {'.git', 'node_modules', '.cache', '.DS_Store'}
lvim.builtin.lualine.style = 'default'

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  'bash', 'c', 'javascript', 'json', 'lua', 'python', 'typescript', 'css',
  'rust', 'java', 'yaml'
}

lvim.builtin.treesitter.ignore_install = {'haskell'}
lvim.builtin.treesitter.highlight.enabled = true

vim.g.nvim_tree_group_empty = 1
vim.g.nvim_tree_gitignore = 1

-- generic LSP settings
-- you can set a custom on_attach function that will be used for all the language servers
-- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end
-- you can overwrite the null_ls setup table (useful for setting the root_dir function)
-- lvim.lsp.null_ls.setup = {
--   root_dir = require("lspconfig").util.root_pattern("Makefile", ".git", "node_modules"),
-- }
-- or if you need something more advanced
-- lvim.lsp.null_ls.setup.root_dir = function(fname)
--   if vim.bo.filetype == "javascript" then
--     return require("lspconfig/util").root_pattern("Makefile", ".git", "node_modules")(fname)
--       or require("lspconfig/util").path.dirname(fname)
--   elseif vim.bo.filetype == "php" then
--     return require("lspconfig/util").root_pattern("Makefile", ".git", "composer.json")(fname) or vim.fn.getcwd()
--   else
--     return require("lspconfig/util").root_pattern("Makefile", ".git")(fname) or require("lspconfig/util").path.dirname(fname)
--   end
-- end

-- set a formatter if you want to override the default lsp one (if it exists)
-- lvim.lang.python.formatters = {
--   {
--     exe = "black",
--   }
-- }
-- set an additional linter
-- lvim.lang.python.linters = {
--   {
--     exe = "flake8",
--   }
-- }

lvim.lang.lua.formatters = {
  {
    exe = 'lua-format',
    args = {
      '-i', '--break-after-table-lb', '--break-before-table-rb',
      '--double-quote-to-single-quote', '--indent-width=2', '--tab-width=2',
      '--continuation-indent-width=2'
    }
  }
}

-- LuaFormatter off
-- Additional Plugins
lvim.plugins = {
  {'folke/tokyonight.nvim'},
  {'tpope/vim-repeat'},
  {'tpope/vim-surround', keys = {'c', 'd', 'y'}},
  {
    'folke/todo-comments.nvim',
    event = 'BufRead',
    config = function()
      require('todo-comments').setup {
        highlight = {
          keyword = 'fg',
          pattern = [[.*<(KEYWORDS) (\([^\)]*\))?:]]
        },
        search = {pattern = [[\b(KEYWORDS) (\([^\)]*\))?:]]}
      }
    end
  },
  {'folke/trouble.nvim', cmd = 'TroubleToggle'},
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'BufRead',
    setup = function()
      vim.g.indentLine_enabled = 1
      vim.g.indent_blankline_char = '▏'
      vim.g.indent_blankline_filetype_exclude = {
        'help', 'terminal', 'dashboard', 'packer', 'lsp-installer', 'lspinfo'
      }
      vim.g.indent_blankline_buftype_exclude = {'terminal'}
      vim.g.indent_blankline_show_trailing_blankline_indent = false
      vim.g.indent_blankline_show_first_indent_level = false
      vim.g.indent_blankline_use_treesitter = true
    end
  },
  {'simrat39/symbols-outline.nvim', cmd = 'SymbolsOutline'},
  {
    'nvim-telescope/telescope-project.nvim',
    event = 'BufWinEnter',
    setup = function() vim.cmd [[packadd telescope.nvim]] end
  },
  {'segeljakt/vim-silicon'},
  {
    "ethanholz/nvim-lastplace",
    event = "BufRead",
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = {
          "gitcommit", "gitrebase", "svn", "hgcommit",
        },
        lastplace_open_folds = true,
      })
    end,
  },
  {
    "folke/persistence.nvim",
      event = "VimEnter",
      module = "persistence",
      config = function()
        require("persistence").setup {
          dir = vim.fn.expand(vim.fn.stdpath "config" .. "/session/"),
          options = { "buffers", "curdir", "tabpages", "winsize" },
        }
    end,
  },
}
-- LuaFormatter on

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
lvim.autocommands.custom_groups = {
  {'TermOpen,TermEnter', 'term://*', 'startinsert!'},
  {'TermEnter', 'term://*', 'setlocal nonumber norelativenumber signcolumn=no'}
}

vim.opt.relativenumber = true
vim.opt.wildmode = {'longest:full', 'full'}
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}
vim.opt.timeoutlen = 300
vim.opt.foldenable = false
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.markdown_fenced_languages = {
  'bash', 'json', 'javascript', 'python', 'java', 'groovy', 'go', 'rust'
}

if vim.fn.executable('rg') then
  vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
  vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- https://jdhao.github.io/2020/03/14/nvim_search_replace_multiple_file/
-- https://stackoverflow.com/a/51962260
-- https://thoughtbot.com/blog/faster-grepping-in-vim
vim.cmd('packadd cfilter')
