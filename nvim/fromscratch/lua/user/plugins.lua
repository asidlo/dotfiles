-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

local M = {}

-- load plugin after entering vim ui
M.packer_lazy_load = function(plugin, timer)
    if plugin then
        timer = timer or 0
        vim.defer_fn(function()
            packer.loader(plugin)
        end, timer)
    end
end

M.installed_plugins = function()
    return require('packer.plugin_utils').list_installed_plugins()
end

-- Have packer use a popup window
M.init = function(opts)
    opts = opts or {}
    local defaults = {
        auto_clean = true,
        max_jobs = 40,
        compile_on_sync = true,
        git = { clone_timeout = 300 },
        log = { level = "warn" },
        display = {
            working_sym = ' ',
            error_sym = ' ',
            done_sym = ' ',
            removed_sym = ' ',
            moved_sym = ' ',
            open_fn = function()
                return require('packer.util').float({ border = 'rounded' })
            end,
        },
        luarocks = {
            python_cmd = 'python3' -- Set the python command to use for running hererocks
        }
    }
    local cfg = vim.tbl_deep_extend('force', defaults, opts)
    packer.init(cfg)

    -- if vim.fn.has('mac') == 1 then
    --     vim.fn.setenv("MACOSX_DEPLOYMENT_TARGET", "10.15")
    -- end
    -- local rocks = require('packer.luarocks')
    -- rocks.install_commands()
    -- rocks.setup_paths()
end

-- Install your plugins here
M.startup = function()
    -- https://jdhao.github.io/2020/03/14/nvim_search_replace_multiple_file/
    -- https://stackoverflow.com/a/51962260
    -- https://thoughtbot.com/blog/faster-grepping-in-vim
    vim.cmd('packadd cfilter')

    packer.startup(function(use)
        use('wbthomason/packer.nvim')
        use('folke/tokyonight.nvim')
        use(require('user.autopairs').use())
        -- use {
        --     'fgheng/winbar.nvim',
        --     config = function()
        --         local colors_ok, colors = pcall(require, 'tokyonight.colors')
        --         if not colors_ok then
        --             return
        --         end
        --         colors = colors.setup()
        --         require('winbar').setup({
        --             enabled = true,
        --
        --             show_file_path = true,
        --             show_symbols = true,
        --
        --             colors = {
        --                 path = colors.comment,
        --                 file_name = colors.comment,
        --                 symbols = '',
        --             },
        --
        --             icons = {
        --                 file_icon_default = '',
        --                 seperator = '>',
        --                 editor_state = '●',
        --                 lock_icon = '',
        --             },
        --
        --             exclude_filetype = {
        --                 'help',
        --                 'startify',
        --                 'dashboard',
        --                 'packer',
        --                 'neogitstatus',
        --                 'NvimTree',
        --                 'Trouble',
        --                 'alpha',
        --                 'lir',
        --                 'Outline',
        --                 'spectre_panel',
        --                 'toggleterm',
        --                 'qf',
        --             }
        --         })
        --     end
        -- }

        use({
            'karb94/neoscroll.nvim',
            config = function ()
                require('neoscroll').setup()
            end
        })
        use({
            'numToStr/Comment.nvim',
            config = function()
                require('user.comment')
            end
            -- keys = { "gc", "gb" },
        })
        use('kyazdani42/nvim-web-devicons')
        use({
            'kyazdani42/nvim-tree.lua',
            config = function()
                require('user.nvim-tree')
            end
            -- cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        })
        use({
            'akinsho/bufferline.nvim',
            config = function()
                require('user.bufferline')
            end
        })
        use('moll/vim-bbye')
        use({
            'j-hui/fidget.nvim',
            config = function()
                require('fidget').setup({
                    text = {
                        spinner = 'dots',
                    },
                    timer = {
                        pinner_rate = 125, -- frame rate of spinner animation, in ms
                        fidget_decay = 2000, -- how long to keep around empty fidget, in ms
                        task_decay = 2000, -- how long to keep around completed task, in ms
                    },
                })
            end,
        })
        use({
            'nvim-lualine/lualine.nvim',
            requires = { 'folke/tokyonight.nvim', 'SmiteshP/nvim-gps' },
            config = function()
                require('user.lualine')
            end
            -- after = { 'nvim-gps' },
        })
        use({
            'akinsho/toggleterm.nvim',
            config = function()
                require('user.toggleterm')
            end
        })
        use({
            'ahmedkhalf/project.nvim',
            config = function()
                require('user.project')
            end
        })
        use('lewis6991/impatient.nvim')

        use({
            'lukas-reineke/indent-blankline.nvim',
            config = function()
                require('user.indentline')
            end
            -- event = 'BufRead'
        })

        use({
            'goolord/alpha-nvim',
            config = function()
                require('user.alpha')
            end
            -- disable = true,
        })
        use('antoinemadec/FixCursorHold.nvim') -- This is needed to fix lsp doc highlight
        use({
            'folke/which-key.nvim',
            config = function()
                require('user.whichkey')
            end
            -- opt = true,
            -- setup = function()
            --     packer_lazy_load "which-key.nvim"
            -- end,
        })
        use('bronson/vim-visual-star-search')

        --   -- Colorschemes
        --   -- use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
        --   use('lunarvim/darkplus.nvim')

        -- cmp plugins
        use({
            'hrsh7th/nvim-cmp',
            config = function()
                require('user.cmp')
            end,
        })
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
        use({
            'hrsh7th/cmp-emoji',
            -- after = "cmp_luasnip",
        })
        use('f3fora/cmp-spell')
        -- use('uga-rosa/cmp-dictionary')
        use({
            'saecki/crates.nvim',
            requires = { 'nvim-lua/plenary.nvim' },
            config = function()
                local ok, crates = pcall(require, 'crates')
                if not ok then
                    return
                end
                crates.setup()
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
            config = function()
                require('user.lspconfig')
            end
            -- after = "nvim-lsp-installer",
        })
        use({
            'williamboman/mason.nvim',
            config = function()
                require('user.mason')
            end
        })
        use({
            'williamboman/mason-lspconfig.nvim',
            config = function()
                require('user.mason-lspconfig')
            end
        })
        use('jose-elias-alvarez/null-ls.nvim')
        use({
            'jay-babu/mason-null-ls.nvim',
            requires = { 'jose-elias-alvarez/null-ls.nvim' },
            config = function()
                require('user.mason-null-ls')
            end
        })
        use('github/copilot.vim')
        -- use({
        --     'williamboman/nvim-lsp-installer',
        --     -- opt = true,
        --     -- setup = function()
        --     --     packer_lazy_load "nvim-lsp-installer"
        --     --     -- reload the current file so lsp actually starts for it
        --     --     vim.defer_fn(function()
        --     --         vim.cmd 'if &ft == "packer" | echo "" | else | silent! e %'
        --     --     end, 0)
        --     -- end,
        -- })
        use({
            'tamago324/nlsp-settings.nvim',
            -- config = function()
            --     require('nlspsettings').setup()
            -- end,
        })
        -- use({ 'Tastyep/structlog.nvim' })
        -- use({
        --     'rcarriga/nvim-notify',
        --     requires = { 'nvim-telescope/telescope.nvim', 'Tastyep/structlog.nvim' },
        --     -- rocks = {'json-lua', 'inspect'}
        -- })
        -- use({
        --     "folke/noice.nvim",
        --     event = "VimEnter",
        --     config = function()
        --         require("noice").setup()
        --     end,
        --     requires = {
        --         -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
        --         "MunifTanjim/nui.nvim",
        --         "rcarriga/nvim-notify",
        --     }
        -- })
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
                    hint_enable = false,
                    hint_prefix = ' ',
                    hint_scheme = 'String',
                    hi_parameter = 'Search',
                    max_height = 22,
                    max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
                    handler_opts = {
                        border = 'rounded', -- double, single, shadow, none
                    },
                    zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
                    padding = '', -- character to pad on left and right of signature can be ' ', or '|'  etc
                    -- toggle_keymap = '<C-h>'
                }
                require('lsp_signature').setup(options)
            end,
        })
        use({
            'ray-x/go.nvim',
            -- after = 'nvim-lsp-installer',
            config = function()
                require('user.go')
            end,
        })
        -- use('leoluz/nvim-dap-go')
        -- use({
        --     'simrat39/rust-tools.nvim',
        --     -- after = 'nvim-lsp-installer',
        --     config = function()
        --         local path = require('nvim-lsp-installer.core.path')
        --         local install_root_dir = path.concat({ vim.fn.stdpath('data'), 'lsp_servers' })
        --
        --         local exe = '/usr/bin/lldb-vscode'
        --         if vim.fn.has('win32') == 1 then
        --             exe = 'C:\\Program Files\\LLVM\\bin\\lldb-vscode.exe'
        --         else
        --             exe = '/usr/local/bin/lldb-vscode'
        --         end
        --
        --         require('rust-tools').setup({
        --             server = {
        --                 cmd = { install_root_dir .. '/rust_analyzer/rust-analyzer' },
        --                 on_attach = require('user.lsp.handlers').on_attach,
        --                 capabilities = require('user.lsp.handlers').capabilities,
        --                 settings = {
        --                     ['rust-analyzer'] = {
        --                         checkOnSave = { command = 'clippy' },
        --                     },
        --                 },
        --             },
        --             dap = {
        --                 adapter = {
        --                     type = 'executable',
        --                     command = exe,
        --                     name = 'rt_lldb',
        --                 },
        --             },
        --         })
        --     end,
        -- })
        -- use('mfussenegger/nvim-jdtls')
        use({
            'simrat39/symbols-outline.nvim',
            setup = function()
                vim.g.symbols_outline = {
                    auto_preview = false
                }
            end
        })
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
            -- event = 'BufRead',
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
        use({
            'folke/trouble.nvim',
            -- cmd = 'TroubleToggle'
        })
        -- Telescope
        use({
            'nvim-telescope/telescope.nvim',
            -- cmd = 'Telescope',
            config = function()
                require('user.telescope')
            end,
        })
        use({
            'nvim-telescope/telescope-ui-select.nvim',
            requires = { 'nvim-telescope/telescope.nvim' },
        })
        use({
            'nvim-telescope/telescope-dap.nvim',
            requires = { 'nvim-telescope/telescope.nvim' },
        })

        -- Treesitter
        use({
            'nvim-treesitter/nvim-treesitter',
            config = function()
                require('user.treesitter')
            end
            -- run = ':TSUpdate',
            -- event = { "BufRead", "BufNewFile" },
        })
        use({
            'JoosepAlviste/nvim-ts-context-commentstring',
            requires = { 'nvim-treesitter/nvim-treesitter' },
            after = 'nvim-treesitter',
        })
        use({
            'nvim-treesitter/nvim-treesitter-textobjects',
            requires = { 'nvim-treesitter/nvim-treesitter' },
            after = 'nvim-treesitter',
        })

        -- Gi
        use({
            'lewis6991/gitsigns.nvim',
            config = function()
                require('user.gitsigns').setup()
            end,
            -- event = { 'BufEnter' },
        })

        use({
            'rhysd/git-messenger.vim',
            setup = function()
                vim.g.git_messenger_floating_win_opts = { border = 'rounded' }
            end
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
            -- event = 'BufRead',
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
        -- use('wincent/loupe')
        -- use({
        --     'wincent/ferret',
        --     setup = function()
        --         vim.g.FerretMap = 0
        --     end
        -- })
        use('romainl/vim-qf')
        use('carlsmedstad/vim-bicep')
        use({
            'SmiteshP/nvim-gps',
            requires = { 'nvim-treesitter/nvim-treesitter' },
            after = 'nvim-treesitter',
        })
        use {
            "SmiteshP/nvim-navic",
            requires = "neovim/nvim-lspconfig"
        }
        use {
            'vim-test/vim-test'
        }
        use {
            'ThePrimeagen/harpoon'
        }
        use {
            "nvim-neotest/neotest",
            requires = {
                "nvim-lua/plenary.nvim",
                "nvim-treesitter/nvim-treesitter",
                "antoinemadec/FixCursorHold.nvim",
                "nvim-neotest/neotest-vim-test",
            },
            config = function()
                require("neotest").setup({
                    adapters = {
                        require("neotest-vim-test")({
                            ignore_file_types = { "python", "vim", "lua" },
                        }),
                    },
                })
            end
        }
        use {
            'anuvyklack/hydra.nvim',
            -- requires = { 'sindrets/winshift.nvim', 'mrjones2014/smart-splits.nvim' },
            requires = 'anuvyklack/keymap-layer.nvim',
            config = function()
                require('user.hydra').setup()
            end
        }
        use { 'towolf/vim-helm' }
    end)
end

return M
