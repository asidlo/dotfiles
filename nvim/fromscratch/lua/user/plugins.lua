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
    use('wbthomason/packer.nvim')
    use('nvim-lua/popup.nvim')
    use('nvim-lua/plenary.nvim')
    use('windwp/nvim-autopairs')
    use('numToStr/Comment.nvim')
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
    use('bronson/vim-visual-star-search')

    -- Colorschemes
    -- use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
    use('lunarvim/darkplus.nvim')
    use('folke/tokyonight.nvim')

    -- cmp plugins
    use('hrsh7th/nvim-cmp')
    use('hrsh7th/cmp-omni')
    use('hrsh7th/cmp-buffer')
    use('hrsh7th/cmp-path')
    -- use('hrsh7th/cmp-cmdline')
    use('saadparwaiz1/cmp_luasnip')
    use('hrsh7th/cmp-nvim-lsp')
    use('hrsh7th/cmp-nvim-lua')
    use('f3fora/cmp-spell')
    -- use('uga-rosa/cmp-dictionary')
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
    use('L3MON4D3/LuaSnip')
    use('rafamadriz/friendly-snippets')

    -- LSP
    use('neovim/nvim-lspconfig')
    use('williamboman/nvim-lsp-installer')
    use({
        'tamago324/nlsp-settings.nvim',
        -- config = function()
        --     require('nlspsettings').setup()
        -- end,
    })
    use('jose-elias-alvarez/null-ls.nvim')
    use('Pocco81/dap-buddy.nvim')
    use('b0o/schemastore.nvim')
    use({
        'mfussenegger/nvim-dap',
        config = function()
            require('user.dap')
        end,
    })
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
    -- use('ray-x/lsp_signature.nvim')
    use({
        'ray-x/go.nvim',
        config = function()
            local path = require('nvim-lsp-installer.core.path')
            local install_root_dir = path.concat({ vim.fn.stdpath('data'), 'lsp_servers' })
            require('go').setup({
                lsp_keymaps = false,
                gopls_cmd = { install_root_dir .. '/go/gopls' },
                filstruct = 'gopls',
                dap_debug = false,
                dap_debug_gui = false,
            })
        end,
    })
    use('leoluz/nvim-dap-go')
    use({
        'simrat39/rust-tools.nvim',
        config = function()
            local path = require('nvim-lsp-installer.core.path')
            local install_root_dir = path.concat({ vim.fn.stdpath('data'), 'lsp_servers' })

            local exe = '/usr/bin/lldb-vscode'
            if vim.fn.has('win32') == 1 then
                exe = 'C:\\Program Files\\LLVM\\bin\\lldb-vscode.exe'
            else
                exe = '/usr/local/bin/lldb-vscode'
            end

            require('rust-tools').setup({
                server = {
                    cmd = { install_root_dir .. '/rust/rust-analyzer' },
                    on_attach = require('user.lsp.handlers').on_attach,
                    capabilities = require('user.lsp.handlers').capabilities,
                    settings = {
                        ['rust-analyzer'] = {
                            checkOnSave = { command = 'clippy' },
                        },
                    },
                },
                dap = {
                    adapter = {
                        type = 'executable',
                        command = exe,
                        name = 'rt_lldb',
                    },
                },
            })
        end,
    })
    use('mfussenegger/nvim-jdtls')
    use('simrat39/symbols-outline.nvim')
    use({
        'stevearc/aerial.nvim',
        config = function()
            require('aerial').setup()
        end,
    })
    -- use({ 'OmniSharp/omnisharp-vim', })
    -- use('nickspoons/vim-sharpenup')
    use ('Hoffs/omnisharp-extended-lsp.nvim')

    use({
        'folke/todo-comments.nvim',
        event = 'BufRead',
        config = function()
            require('todo-comments').setup({
                highlight = {
                    keyword = 'wide',
                    pattern = [[.*<(KEYWORDS) ?(\([^\)]*\))?:]],
                },
                search = { pattern = [[\b(KEYWORDS) ?(\([^\)]*\))?:]] },
            })
        end,
    })
    use({ 'folke/trouble.nvim', cmd = 'TroubleToggle' })

    -- Telescope
    use('nvim-telescope/telescope.nvim')
    use('nvim-telescope/telescope-ui-select.nvim')
    use('nvim-telescope/telescope-dap.nvim')

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
    use({
        'ten3roberts/qf.nvim',
        config = function()
            require('qf').setup({})
        end,
    })
    -- use 'TamaMcGlinn/quickfixdd'
    use 'wincent/loupe'
    use 'wincent/ferret'
    use 'romainl/vim-qf'
    use({ 'segeljakt/vim-silicon' })

    use('carlsmedstad/vim-bicep')

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require('packer').sync()
    end
end)
