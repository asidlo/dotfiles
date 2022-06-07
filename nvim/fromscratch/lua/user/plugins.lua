local fn = vim.fn
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"

vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e222a" })

if fn.empty(fn.glob(install_path)) > 0 then
    print "Cloning packer .."

    fn.system { "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path }

    -- install plugins + compile their configs
    vim.cmd "packadd packer.nvim"
    require "plugins"
    vim.cmd "PackerSync"
end

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

-- load plugin after entering vim ui
local packer_lazy_load = function(plugin, timer)
    if plugin then
        timer = timer or 0
        vim.defer_fn(function()
            packer.loader(plugin)
        end, timer)
    end
end

-- Have packer use a popup window
packer.init({
    auto_clean = true,
    compile_on_sync = true,
    git = { clone_timeout = 6000 },
    display = {
        working_sym = " ﲊ",
        error_sym = "✗ ",
        done_sym = " ",
        removed_sym = " ",
        moved_sym = "",
        open_fn = function()
            return require("packer.util").float { border = "rounded" }
        end,
    },
})

-- Install your plugins here
packer.startup(function(use)
    use('wbthomason/packer.nvim')
    use('nvim-lua/popup.nvim')
    use('nvim-lua/plenary.nvim')
    use({
        'windwp/nvim-autopairs',
        -- after = "nvim-cmp",
    })
    use({
        'numToStr/Comment.nvim',
        -- keys = { "gc", "gb" },
    })
    use('kyazdani42/nvim-web-devicons')
    use({
        'kyazdani42/nvim-tree.lua',
        -- cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    })
    use('akinsho/bufferline.nvim')
    use('moll/vim-bbye')
    use({
        'nvim-lualine/lualine.nvim',
        requires = { 'folke/tokyonight.nvim' }
    })
    use('akinsho/toggleterm.nvim')
    use('ahmedkhalf/project.nvim')
    use('lewis6991/impatient.nvim')

    use({
        'lukas-reineke/indent-blankline.nvim',
        -- event = 'BufRead'
    })

    use({
        'goolord/alpha-nvim',
        -- disable = true,
    })
    use('antoinemadec/FixCursorHold.nvim') -- This is needed to fix lsp doc highlight
    use({
        'folke/which-key.nvim',
        -- opt = true,
        -- setup = function()
        --     packer_lazy_load "which-key.nvim"
        -- end,
    })
    use('bronson/vim-visual-star-search')

    -- Colorschemes
    -- use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
    use('lunarvim/darkplus.nvim')
    use('folke/tokyonight.nvim')

    -- cmp plugins
    use('hrsh7th/nvim-cmp')
    use('hrsh7th/cmp-omni')
    use({
        'hrsh7th/cmp-buffer',
        -- after = "cmp-nvim-lsp",
    })
    use({
        'hrsh7th/cmp-path',
        -- after = "cmp-buffer",
    })
    -- use('hrsh7th/cmp-cmdline')
    use({
        'saadparwaiz1/cmp_luasnip',
        -- after = "LuaSnip",
    })
    use({
        'hrsh7th/cmp-nvim-lsp',
        -- after = "cmp-nvim-lua",
    })
    use({
        'hrsh7th/cmp-nvim-lua',
        -- after = "cmp_luasnip",
    })
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
    use({
        'L3MON4D3/LuaSnip',
        -- wants = "friendly-snippets",
        -- after = "nvim-cmp",
    })
    use({
        'rafamadriz/friendly-snippets',
        -- event = "InsertEnter"
    })

    -- LSP
    use({
        'neovim/nvim-lspconfig',
        -- after = "nvim-lsp-installer",
    })
    use({
        'williamboman/nvim-lsp-installer',
        -- opt = true,
        -- setup = function()
        --     packer_lazy_load "nvim-lsp-installer"
        --     -- reload the current file so lsp actually starts for it
        --     vim.defer_fn(function()
        --         vim.cmd 'if &ft == "packer" | echo "" | else | silent! e %'
        --     end, 0)
        -- end,
    })
    use({
        'tamago324/nlsp-settings.nvim',
        -- config = function()
        --     require('nlspsettings').setup()
        -- end,
    })
    use({ "Tastyep/structlog.nvim" })
    use({
        "rcarriga/nvim-notify",
        -- config = function()
        --   require("lvim.core.notify").setup()
        -- end,
        requires = { "nvim-telescope/telescope.nvim", 'Tastyep/structlog.nvim' },
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
    use({
        'ray-x/lsp_signature.nvim',
        config = function()
            local options = {
                bind = true,
                doc_lines = 0,
                floating_window = true,
                fix_pos = true,
                hint_enable = true,
                hint_prefix = " ",
                hint_scheme = "String",
                hi_parameter = "Search",
                max_height = 22,
                max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
                handler_opts = {
                    border = "single", -- double, single, shadow, none
                },
                zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
                padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
            }
            require('lsp_signature').setup(options)
        end
    })
    use({
        'ray-x/go.nvim',
        -- after = 'nvim-lsp-installer',
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
        -- after = 'nvim-lsp-installer',
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
    use('Hoffs/omnisharp-extended-lsp.nvim')

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
    use({
        'nvim-telescope/telescope.nvim',
        cmd = "Telescope",
    })
    use('nvim-telescope/telescope-ui-select.nvim')
    use('nvim-telescope/telescope-dap.nvim')

    -- Treesitter
    use({
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        -- event = { "BufRead", "BufNewFile" },
    })
    use({
        'JoosepAlviste/nvim-ts-context-commentstring',
        -- after = 'nvim-treesitter'
    })
    use({
        'nvim-treesitter/nvim-treesitter-textobjects',
        -- after = 'nvim-treesitter'
    })

    -- Gi
    use({
        'lewis6991/gitsigns.nvim',
        -- opt = true,
        -- setup = function()
        --     packer_lazy_load "gitsigns.nvim"
        -- end,
        -- event = "BufEnter",
    })

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
    use {
        "SmiteshP/nvim-gps",
        requires = "nvim-treesitter/nvim-treesitter"
    }
end)
