local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system({
        'git',
        'clone',
        '--depth',
        '1',
        'https://github.com/wbthomason/packer.nvim',
        install_path,
    })
    print('Installing packer close and reopen Neovim...')
    vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
-- vim.cmd([[
--   augroup packer_user_config
--     autocmd!
--     autocmd BufWritePost plugins.lua source <afile> | PackerSync
--   augroup end
-- ]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

-- Have packer use a popup window
packer.init({
    display = {
        open_fn = function()
            return require('packer.util').float({ border = 'rounded' })
        end,
    },
})

-- Install your plugins here
return packer.startup(function(use)
    -- My plugins here
    use('wbthomason/packer.nvim') -- Have packer manage itself
    use('nvim-lua/popup.nvim') -- An implementation of the Popup API from vim in Neovim
    use('nvim-lua/plenary.nvim') -- Useful lua functions used ny lots of plugins
    use('windwp/nvim-autopairs') -- Autopairs, integrates with both cmp and treesitter
    use('numToStr/Comment.nvim') -- Easily comment stuff
    use('kyazdani42/nvim-web-devicons')
    use('kyazdani42/nvim-tree.lua')
    use('akinsho/bufferline.nvim')
    use('moll/vim-bbye')
    use('nvim-lualine/lualine.nvim')
    use('akinsho/toggleterm.nvim')
    use('ahmedkhalf/project.nvim')
    use('lewis6991/impatient.nvim')
    use('lukas-reineke/indent-blankline.nvim')
    use('goolord/alpha-nvim')
    use('antoinemadec/FixCursorHold.nvim') -- This is needed to fix lsp doc highlight
    use('folke/which-key.nvim')

    -- Colorschemes
    -- use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
    use('lunarvim/darkplus.nvim')
    use('folke/tokyonight.nvim')

    -- cmp plugins
    use('hrsh7th/nvim-cmp') -- The completion plugin
    use('hrsh7th/cmp-buffer') -- buffer completions
    use('hrsh7th/cmp-path') -- path completions
    use('hrsh7th/cmp-cmdline') -- cmdline completions
    use('saadparwaiz1/cmp_luasnip') -- snippet completions
    use('hrsh7th/cmp-nvim-lsp')
    use('hrsh7th/cmp-nvim-lua')
    use('f3fora/cmp-spell')
    use('uga-rosa/cmp-dictionary')
    use({
        'saecki/crates.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('crates').setup()
        end,
    })
    use({
        'PasiBergman/cmp-nuget',
        requires = {
            'nvim-lua/plenary.nvim',
        },
    })

    -- snippets
    use('L3MON4D3/LuaSnip') --snippet engine
    use('rafamadriz/friendly-snippets') -- a bunch of snippets to use

    -- LSP
    use('neovim/nvim-lspconfig') -- enable LSP
    use('williamboman/nvim-lsp-installer') -- simple to use language server installer
    use({
        'tamago324/nlsp-settings.nvim',
        -- config = function()
        --     require('nlspsettings').setup()
        -- end,
    })
    use('jose-elias-alvarez/null-ls.nvim') -- for formatters and linters
    use('Pocco81/DAPInstall.nvim')
    use('b0o/schemastore.nvim')
    use('mfussenegger/nvim-dap')
    use({
        'rcarriga/nvim-dap-ui',
        requires = { 'mfussenegger/nvim-dap' },
        config = function()
            require('dapui').setup()
        end,
    })
    use({
        'theHamsta/nvim-dap-virtual-text',
        config = function()
            require('nvim-dap-virtual-text').setup()
        end,
    })
    use({
        'ray-x/go.nvim',
        config = function()
            local path = require 'nvim-lsp-installer.path'
            local install_root_dir = path.concat {vim.fn.stdpath 'data', 'lsp_servers'}
            require('go').setup({
                gopls_cmd = {install_root_dir .. '/go/gopls'},
                filstruct = 'gopls',
                dap_debug = true,
                dap_debug_gui = true
            })
        end,
    })
    use({
        'simrat39/rust-tools.nvim',
        config = function()
            local path = require 'nvim-lsp-installer.path'
            local install_root_dir = path.concat {vim.fn.stdpath 'data', 'lsp_servers'}
            require('rust-tools').setup({
                server = {
                    -- cmd = {install_root_dir .. '/rust/rust-analyzer'},
                    on_attach = require('user.lsp.handlers').on_attach,
                    capabilities = require('user.lsp.handlers').capabilities,
                    settings = {
                        ['rust-analyzer'] = {
                            checkOnSave = { command = 'clippy' },
                        }
                    }
                }
            })
        end
    })
    use('mfussenegger/nvim-jdtls')

    use({
        'folke/todo-comments.nvim',
        event = 'BufRead',
        config = function()
            require('todo-comments').setup({
                highlight = {
                    keyword = 'wide',
                    pattern = [[.*<(KEYWORDS) (\([^\)]*\))?:]],
                },
                search = { pattern = [[\b(KEYWORDS) (\([^\)]*\))?:]] },
            })
        end,
    })
    use({ 'folke/trouble.nvim', cmd = 'TroubleToggle' })

    -- Telescope
    use('nvim-telescope/telescope.nvim')
    use('nvim-telescope/telescope-ui-select.nvim')

    -- Treesitter
    use({
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
    })
    use('JoosepAlviste/nvim-ts-context-commentstring')
    use({ 'nvim-treesitter/nvim-treesitter-textobjects' })

    -- Gi
    use('lewis6991/gitsigns.nvim')

    -- Tpope
    use('tpope/vim-repeat')
    use('tpope/vim-surround')
    use('tpope/vim-unimpaired')
    use('tpope/vim-obsession')
    use('tpope/vim-fugitive')

    use({
        'ethanholz/nvim-lastplace',
        event = 'BufRead',
        config = function()
            require('nvim-lastplace').setup({
                lastplace_ignore_buftype = { 'quickfix', 'nofile', 'help' },
                lastplace_ignore_filetype = {
                    'gitcommit',
                    'gitrebase',
                    'svn',
                    'hgcommit',
                },
                lastplace_open_folds = true,
            })
        end,
    })
    use({
        'aymericbeaumet/vim-symlink',
        event = 'BufRead',
        requires = {
            { 'moll/vim-bbye' },
        },
    })
    use({ 'segeljakt/vim-silicon' })

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require('packer').sync()
    end
end)
