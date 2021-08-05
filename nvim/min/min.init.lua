-- Settings
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.showmode = false
vim.opt.hidden = true
vim.opt.autoread = true
vim.opt.autowriteall = true
vim.opt.mouse = 'a'
vim.opt.completeopt = {'menuone', 'noselect'}
vim.opt.clipboard = 'unnamed'
vim.opt.wildmode = {'longest:full', 'full'}
vim.opt.updatetime = 300
vim.opt.cmdheight = 2
vim.opt.shortmess:append('c')
vim.opt.wildignore = {'*.o', '*~', '*.pyc', '*.class', '*/.git/*', '*/.hg/*', '*/.svn/*', '*/.DS_Store'}
vim.opt.timeoutlen = 500
vim.opt.listchars = {tab = '>-', trail = '-', nbsp = '+'}
vim.opt.spellsuggest = '15'
vim.opt.dictionary = '/usr/share/dict/words'

if vim.fn.executable('rg') then
    vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
    vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.modeline = false
vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.foldenable = false
vim.opt.signcolumn = 'yes'
vim.opt.list = true

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.colors_name = 'dracula'
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.mapleader = ','

vim.g.markdown_fenced_languages = {'bash', 'json', 'javascript', 'python', 'java', 'groovy', 'go', 'rust'}

local disabled_built_ins = {
    "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers", "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
    "getscript", "getscriptPlugin", "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper",
    "spellfile_plugin", "matchit"
}

for _, plugin in pairs(disabled_built_ins) do vim.g["loaded_" .. plugin] = 1 end

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function _G.new_buf(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    local buf = vim.api.nvim_create_buf(true, true)
    local content = {}
    for _, obj in ipairs(objects) do for _, line in ipairs(vim.split(obj, '\n')) do table.insert(content, line) end end
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)
    vim.cmd('b ' .. buf)
end

--- Creates key mappings to reduce typing
---@param mode string 'n' | 'v' | 'i'...etc
---@param map string keys to be mapped
---@param key string
---@param opts any
function _G.set_keymap(mode, map, key, opts)
    if opts == nil then opts = {noremap = true, silent = true} end
    vim.api.nvim_set_keymap(mode, map, key, opts)
end

function _G.set_buf_keymap(buf, mode, map, key, opts)
    if opts == nil then opts = {noremap = true, silent = true} end
    vim.api.nvim_buf_set_keymap(buf, mode, map, key, opts)
end

-- Until they release the `vim.lsp.util.formatexpr()`
-- https://github.com/neovim/neovim/issues/12528
-- https://github.com/neovim/neovim/pull/12547
-- https://github.com/neovim/neovim/pull/13138
--
--- Implements an LSP `formatexpr`-compatible
-- @param start_line 1-indexed line, defaults to |v:lnum|
-- @param end_line 1-indexed line, calculated based on {start_line} and |v:count|
-- @param timeout_ms optional, defaults to 500ms
function _G.lsp_formatexpr(start_line, end_line, timeout_ms)
    timeout_ms = timeout_ms or 500

    if not start_line or not end_line then
        if vim.fn.mode() == 'i' or vim.fn.mode() == 'R' then
            -- `formatexpr` is also called when exceeding `textwidth` in insert mode
            -- fall back to internal formatting
            return 1
        end
        start_line = vim.v.lnum
        end_line = start_line + vim.v.count - 1
    end

    if start_line > 0 and end_line > 0 then
        local end_char = vim.fn.col('$')
        vim.lsp.buf.range_formatting({}, {start_line, 0}, {end_line, end_char})
    end

    -- do not run builtin formatter.
    return 0
end

function _G.nvim_create_augroups(definitions)
    for group_name, definition in pairs(definitions) do
        vim.api.nvim_command('augroup ' .. group_name)
        vim.api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            local command = table.concat(vim.tbl_flatten {'autocmd', def}, ' ')
            vim.api.nvim_command(command)
        end
        vim.api.nvim_command('augroup END')
    end
end

-- Augroups
local autocmds = {
    nvim_settings = {
        {[[TextYankPost * silent! lua require'vim.highlight'.on_yank()]]},
        {[[TermOpen,TermEnter term://* startinsert!]]},
        {[[TermEnter term://* setlocal nonumber norelativenumber signcolumn=no]]}
    },
    filetype_settings = {
        {[[FileType vim setlocal foldmethod=marker foldenable]]},
        {[[FileType xml setlocal foldmethod=indent foldlevelstart=999 foldminlines=0]]},
        {[[FileType zsh setlocal foldmethod=marker ]]},
        {[[FileType markdown setlocal textwidth=79 expandtab tabstop=2 shiftwidth=2 ]]},
        {[[FileType lua setlocal expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType text,asciidoc setlocal textwidth=79 expandtab tabstop=4 shiftwidth=4 spell]]},
        {"FileType markdown nmap ]] :execute '/^--\\+' <bar> :noh<CR>"},
        {"FileType markdown nmap [[ :execute '?^--\\+' <bar> :noh<CR>"},
        {[[FileType java,groovy setlocal foldlevel=2 colorcolumn=120 expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType json,jsonc setlocal foldlevel=2 expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType rust setlocal expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType go setlocal noexpandtab tabstop=4 shiftwidth=4]]},
        {[[FileType cpp setlocal makeprg=clang++\ -Wall\ -std=c++17]]},
        {[[FileType c,cpp setlocal formatprg=clang-format commentstring=\/\/\ %s]]},
        {[[BufEnter *gitconfig setlocal filetype=gitconfig]]}, {[[FileType gitcommit setlocal spell]]}
    },
    file_history = {{[[BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]}},
    dracula_customization = {
        {[[ColorScheme dracula highlight SpellBad gui=undercurl]]},
        {[[ColorScheme dracula highlight DraculaDiffDelete guibg=DraculaFg]]},
        {[[ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline]]}
    }
}
nvim_create_augroups(autocmds)

-- Keep it centered
set_keymap('n', 'Y', 'y$')
set_keymap('n', 'n', 'nzzzv')
set_keymap('n', 'N', 'Nzzzv')
set_keymap('n', 'J', 'mzJ`z')

-- Undo break points
set_keymap('i', ',', ',<C-g>u')
set_keymap('i', '.', '.<C-g>u')
set_keymap('i', '!', '!<C-g>u')
set_keymap('i', '?', '?<C-g>u')

-- Jumplist mutations
set_keymap('n', 'k', [[(v:count > 5 ? "m'" . v:count : "") . 'k']], {expr = true, noremap = true})
set_keymap('n', 'j', [[(v:count > 5 ? "m'" . v:count : "") . 'j']], {expr = true, noremap = true})

set_keymap('n', '<Up>', 'gk')
set_keymap('n', '<Down>', 'gj')
-- set_keymap('n', 'j', 'gj')
-- set_keymap('n', 'k', 'gk')
set_keymap('n', '<Leader>cd', '<Cmd>cd %:p:h | pwd<CR>')
set_keymap('n', '<Leader>p', '<Cmd>lua stdout()<CR>')

set_keymap('t', '<Esc>', '<C-\\><C-n>')
set_keymap('t', '<A-h>', '<C-\\><C-N><C-w>h')
set_keymap('t', '<A-j>', '<C-\\><C-N><C-w>j')
set_keymap('t', '<A-k>', '<C-\\><C-N><C-w>k')
set_keymap('t', '<A-l>', '<C-\\><C-N><C-w>l')
set_keymap('i', '<A-h>', '<C-\\><C-N><C-w>h')
set_keymap('i', '<A-j>', '<C-\\><C-N><C-w>j')
set_keymap('i', '<A-k>', '<C-\\><C-N><C-w>k')
set_keymap('i', '<A-l>', '<C-\\><C-N><C-w>l')
set_keymap('n', '<A-h>', '<C-\\><C-N><C-w>h')
set_keymap('n', '<A-j>', '<C-\\><C-N><C-w>j')
set_keymap('n', '<A-k>', '<C-\\><C-N><C-w>k')
set_keymap('n', '<A-l>', '<C-\\><C-N><C-w>l')

-- https://jdhao.github.io/2020/03/14/nvim_search_replace_multiple_file/
-- https://stackoverflow.com/a/51962260
-- https://thoughtbot.com/blog/faster-grepping-in-vim
vim.cmd('packadd cfilter')

local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

local install_pkgs = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
    install_pkgs = true;
end

-- Packages
local packer = require('packer')

packer.init {
    display = {
        open_cmd = 'topleft 55vnew [packer]' -- An optional command to open a window for packer's display
    }
}

packer.startup(function()
    use 'wbthomason/packer.nvim'

    use {'dracula/vim', as = 'dracula'}

    use {'tpope/vim-unimpaired'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-surround'}
    use {'tpope/vim-obsession'}
    use {'tpope/vim-fugitive'}
    use {'airblade/vim-rooter'}
    use {'moll/vim-bbye'}
    use {'aymericbeaumet/vim-symlink'}
    use {'mtdl9/vim-log-highlighting'}

    use {
        'folke/which-key.nvim',
        config = function() require('which-key').setup {plugins = {spelling = {enabled = true}}} end
    }
    use {
        'hoob3rt/lualine.nvim',
        requires = {'kyazdani42/nvim-web-devicons', opt = true},
        config = function() require('lualine').setup {options = {theme = 'dracula'}} end
    }
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function()
            set_keymap('n', '<Leader>n', '<Cmd>NvimTreeToggle<CR>')
            set_keymap('n', '<Leader>N', '<Cmd>NvimTreeFindFile<CR>')
            vim.g.nvim_tree_width = 40
            vim.g.nvim_tree_auto_resize = 0
            vim.g.nvim_tree_window_picker_exclude = {filetype = {'packer', 'qf'}, buftype = {'terminal'}}
        end
    }
    use {
        'simrat39/symbols-outline.nvim',
        config = function() set_keymap('n', '<Leader>o', '<Cmd>SymbolsOutline<CR>') end
    }
    use {
        "folke/trouble.nvim",
        requires = {"kyazdani42/nvim-web-devicons"},
        config = function()
            require('trouble').setup()
            set_keymap('n', '<Leader>tt', '<Cmd>TroubleToggle<CR>')
            set_keymap('n', '<Leader>tr', '<Cmd>TroubleRefresh<CR>')
        end
    }
    use {'norcalli/nvim-colorizer.lua', config = function() require('colorizer').setup() end}
    use {
        'b3nj5m1n/kommentary',
        config = function()
            local cfg = require('kommentary.config')
            cfg.configure_language('lua', {prefer_single_line_comments = true})
            cfg.configure_language('java', {prefer_single_line_comments = true})
            cfg.configure_language('rust', {prefer_single_line_comments = true})
        end
    }
    use {
        "folke/todo-comments.nvim",
        requires = {"nvim-lua/plenary.nvim"},
        config = function()
            require('todo-comments').setup {
                highlight = {keyword = 'fg', pattern = [[.*<(KEYWORDS)(\([^\)]*\))?:]]},
                search = {pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]]}
            }
        end
    }
    use {
        'lewis6991/gitsigns.nvim',
        requires = {'nvim-lua/plenary.nvim'},
        config = function() require('gitsigns').setup() end
    }
    use {
        'simrat39/rust-tools.nvim',
        requires = {
            {'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}, {'nvim-telescope/telescope.nvim'},
            {'mfussenegger/nvim-dap'}
        }
    }
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}},
        config = function()
            local is_unix = function() return vim.fn.has('unix') == 1 and vim.fn.has('macunix') == 0 end

            local fd_cmd = function()
                if is_unix() then return 'fdfind' end
                return 'fd'
            end

            require('telescope').setup {
                pickers = {
                    find_files = {
                        -- TODO: AS - remove once we can pass a list of excluded members and uncomment no_ignore
                        find_command = {
                            fd_cmd(), '-I', '--follow', '--exclude', '.git', '--exclude', 'node_modules', '--exclude',
                            '*.class'
                        },
                        -- no_ignore = true,
                        hidden = true,
                        follow = true
                    }
                }
            }

            set_keymap('n', '<Leader>F', '<Cmd>Telescope find_files<CR>')
            set_keymap('n', '<Leader>f', '<Cmd>Telescope git_files<CR>')
            set_keymap('n', '<Leader>b', '<Cmd>Telescope buffers<CR>')
            set_keymap('n', '<Leader>e', '<Cmd>Telescope oldfiles<CR>')
            set_keymap('n', '<Leader>x', '<Cmd>Telescope keymaps<CR>')
            set_keymap('n', '<Leader>X', '<Cmd>Telescope commands<CR>')
        end
    }
    use {
        'L3MON4D3/LuaSnip',
        requires = {'rafamadriz/friendly-snippets'},
        config = function()
            local ls = require 'luasnip'

            local s = ls.s
            local t = ls.t
            local i = ls.i

            -- ls.config.set_config({history = true, updateevents = "TextChanged,TextChangedI"})

            local function char_count_same(c1, c2)
                local line = vim.api.nvim_get_current_line()
                local _, ct1 = string.gsub(line, c1, '')
                local _, ct2 = string.gsub(line, c2, '')
                return ct1 == ct2
            end

            local function even_count(pattern)
                local line = vim.api.nvim_get_current_line()
                local _, ct = string.gsub(line, pattern, '')
                return ct % 2 == 0
            end

            local function neg(fn, ...) return not fn(...) end

            ls.snippets = {
                all = {
                    s({trig = "("}, {t({"("}), i(1), t({")"}), i(0)}, neg, char_count_same, '%(', '%)'),
                    s({trig = "{"}, {t({"{"}), i(1), t({"}"}), i(0)}, neg, char_count_same, '%{', '%}'),
                    s({trig = "["}, {t({"["}), i(1), t({"]"}), i(0)}, neg, char_count_same, '%[', '%]'),
                    s({trig = "<"}, {t({"<"}), i(1), t({">"}), i(0)}, neg, char_count_same, '<', '>'),
                    s({trig = "'"}, {t({"'"}), i(1), t({"'"}), i(0)}, neg, even_count, '\''),
                    s({trig = "\""}, {t({"\""}), i(1), t({"\""}), i(0)}, neg, even_count, '"'),
                    s({trig = "{;"}, {t({"{", "\t"}), i(1), t({"", "}"}), i(0)})
                }
            }

            require("luasnip/loaders/from_vscode").lazy_load({
                paths = {vim.fn.stdpath('data') .. '/site/pack/packer/start/friendly-snippets/snippets'}
            })

            set_keymap('i', '<C-k>', "<cmd>lua return require'luasnip'.expand_or_jump()<CR>")
            set_keymap('i', '<C-j>', "<cmd>lua return require'luasnip'.jump(-1)<CR>")
            set_keymap('i', '<C-n>', "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'",
                       {silent = true, expr = true})
            set_keymap('s', '<C-n>', "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'",
                       {silent = true, expr = true})
        end
    }
    use {
        'hrsh7th/nvim-compe',
        requires = {'L3MON4D3/LuaSnip'},
        config = function()
            local compe = require('compe')
            local ls = require 'luasnip'

            compe.setup {
                enabled = true,
                source = {
                    path = true,
                    buffer = true,
                    nvim_lsp = true,
                    nvim_lua = true,
                    calc = false,
                    emoji = false,
                    snippets_nvim = false,
                    luasnip = true, -- dont show to trigger with tab
                    treesitter = false,
                    spell = false
                }
            }

            local function check_back_space()
                local col = vim.fn.col('.') - 1
                if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                    return true
                else
                    return false
                end
            end

            function _G.tab_complete()
                if vim.fn.pumvisible() == 1 then
                    return replace_termcodes('<C-n>')
                elseif ls.expand_or_jumpable() then
                    return replace_termcodes("<cmd>lua require'luasnip'.expand_or_jump()<Cr>")
                elseif check_back_space() then
                    return replace_termcodes('<Tab>')
                else
                    return vim.fn['compe#complete']()
                end
            end

            function _G.s_tab_complete()
                if vim.fn.pumvisible() == 1 then
                    return replace_termcodes('<C-p>')
                elseif ls.jumpable(-1) then
                    return replace_termcodes("<cmd>lua require'luasnip'.jump(-1)<CR>")
                else
                    return replace_termcodes('<S-Tab>')
                end
            end

            set_keymap('i', '<C-Space>', 'compe#complete()', {noremap = true, silent = true, expr = true})
            set_keymap('i', '<CR>', 'compe#confirm({"select": v:true, "keys": "<CR>"})',
                       {noremap = true, silent = true, expr = true})
            set_keymap('i', '<C-e>', 'compe#close("<c-e>")', {silent = true, expr = true})
            set_keymap('i', '<Tab>', 'v:lua.tab_complete()', {silent = true, noremap = true, expr = true})
            set_keymap('s', '<Tab>', 'v:lua.tab_complete()', {silent = true, noremap = true, expr = true})
            set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', {silent = true, noremap = true, expr = true})
            set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', {silent = true, noremap = true, expr = true})
        end
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        requires = {'nvim-treesitter/nvim-treesitter-textobjects'},
        config = function()
            local ts = require('nvim-treesitter.configs')

            local plugins = {
                'bash', 'java', 'lua', 'rust', 'toml', 'go', 'gomod', 'json', 'jsonc', 'python', 'dockerfile', 'cpp',
                'c', 'regex'
            }

            ts.setup {
                ensure_installed = plugins,
                highlight = {enable = true},
                incrementalSelection = {enable = true},
                indent = {enable = true, disable = {'java', 'json'}},
                textobjects = {
                    select = {
                        enable = true,
                        keymaps = {
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner'
                        }
                    },
                    lsp_interop = {
                        enable = true,
                        peek_definition_code = {['gp'] = '@function.outer', ['gP'] = '@class.outer'}
                    },
                    move = {
                        enable = true,
                        goto_next_start = {[']m'] = '@function.outer', [']]'] = '@class.outer'},
                        goto_next_end = {[']M'] = '@function.outer', [']['] = '@class.outer'},
                        goto_previous_start = {['[m'] = '@function.outer', ['[['] = '@class.outer'},
                        goto_previous_end = {['[M'] = '@function.outer', ['[]'] = '@class.outer'}
                    }
                }
            }
        end
    }
    use {
        'neovim/nvim-lspconfig',
        requires = {
            {'nvim-lua/lsp_extensions.nvim'}, {'folke/lua-dev.nvim'}, {'glepnir/lspsaga.nvim'},
            {'onsails/lspkind-nvim'}, {'ray-x/lsp_signature.nvim'}, {'simrat39/rust-tools.nvim'},
            {'mfussenegger/nvim-jdtls'}, {'mfussenegger/nvim-dap'}
        },
        config = function()
            local lspconfig = require('lspconfig')
            local rusttools = require('rust-tools')
            local jdtls = require('jdtls')

            local on_attach = function(client, bufnr)
                require('lsp_signature').on_attach({bind = true, use_lspsaga = true})
                require('lspkind').init()
                set_buf_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
                set_buf_keymap(bufnr, 'n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>')
                set_buf_keymap(bufnr, 'n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>')
                set_buf_keymap(bufnr, 'n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>')
                set_buf_keymap(bufnr, 'n', 'gt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>')
                set_buf_keymap(bufnr, 'n', 'g0', '<Cmd>Telescope lsp_document_symbols<CR>')
                set_buf_keymap(bufnr, 'n', '<Leader>ws', '<Cmd>Telescope lsp_workspace_symbols<CR>')
                set_buf_keymap(bufnr, 'n', '<Leader>wl', '<Cmd>lua dump(vim.lsp.buf.list_workspace_folders())<CR>')
                set_buf_keymap(bufnr, 'n', 'K', "<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>")
                set_buf_keymap(bufnr, 'i', '<M-k>', "<Cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>")
                set_buf_keymap(bufnr, 'n', 'gR', "<Cmd>lua require('lspsaga.rename').rename()<CR>")
                set_buf_keymap(bufnr, 'n', '<M-CR>', "<Cmd>lua require('lspsaga.codeaction').code_action()<CR>")
                set_buf_keymap(bufnr, 'x', '<M-CR>',
                               "<Cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>")
                set_buf_keymap(bufnr, 'n', '[d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
                set_buf_keymap(bufnr, 'n', ']d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
                set_buf_keymap(bufnr, 'n', '<M-Space>',
                               "<Cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>")
                set_buf_keymap(bufnr, 'n', 'gK', "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>")
                set_buf_keymap(bufnr, 'n', '<M-d>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>")
                set_buf_keymap(bufnr, 'n', '<M-u>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>")

                if client.resolved_capabilities.document_range_formatting then
                    -- Note that v:lua only supports global functions
                    vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.lsp_formatexpr()')
                end

                if client.resolved_capabilities.document_formatting then
                    set_buf_keymap(0, 'n', 'g=', '<Cmd>lua vim.lsp.buf.formatting()<CR>')
                end

                if client.name == 'jdtls' then
                    require'jdtls.setup'.add_commands()
                    require'jdtls'.setup_dap()
                    set_buf_keymap(bufnr, 'n', '<M-o>', '<Cmd>lua require("lsp.jdtls").organize_imports()<CR>')
                end

                vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
                vim.lsp.handlers['textDocument/publishDiagnostics'] =
                    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {update_in_insert = true})

                -- Set autocommands conditional on server_capabilities
                if client.resolved_capabilities.document_highlight then
                    vim.api.nvim_command [[
                    :hi LspReferenceRead guibg=NONE gui=underline term=underline cterm=underline
                    :hi LspReferenceText guibg=NONE gui=underline term=underline cterm=underline
                    :hi LspReferenceWrite guibg=NONE gui=underline term=underline cterm=underline
                ]]
                    nvim_create_augroups({
                        lsp_document_highlight = {
                            {'CursorHold <buffer> lua vim.lsp.buf.document_highlight()'},
                            {'CursorMoved <buffer> lua vim.lsp.buf.clear_references()'}
                        }
                    })
                end
            end

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true
            capabilities.workspace.configuration = true

            -- https://github.com/neovim/neovim/issues/12970
            vim.lsp.util.apply_text_document_edit = function(text_document_edit, _)
                local text_document = text_document_edit.textDocument
                local bufnr = vim.uri_to_bufnr(text_document.uri)
                vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr)
            end

            rusttools.setup({tools = {server = {on_attach = on_attach}}})

            lspconfig.gopls.setup {
                on_attach = on_attach,
                cmd = {'gopls', '-remote=auto'},
                root_dir = lspconfig.util.root_pattern('go.mod', '.git'),
                settings = {gopls = {analyses = {unusedparams = true}, staticcheck = true}},
                capabilities = capabilities
            }

            lspconfig.jsonls.setup {
                on_attach = on_attach,
                capabilities = capabilities,
                commands = {Format = {function()
                    vim.lsp.buf.range_formatting({}, {0, 0}, {vim.fn.line("$"), 0})
                end}}
            }

            local system_name
            if vim.fn.has("mac") == 1 then
                system_name = "macOS"
            elseif vim.fn.has("unix") == 1 then
                system_name = "Linux"
            elseif vim.fn.has('win32') == 1 then
                system_name = "Windows"
            else
                print("Unsupported system for sumneko")
            end

            -- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
            local sumneko_root_path = vim.fn.expand('~/.local/src/lua-language-server')
            local sumneko_binary = sumneko_root_path .. "/bin/" .. system_name .. "/lua-language-server"

            local luadev = require("lua-dev").setup({
                -- add any options here, or leave empty to use the default settings
                lspconfig = {
                    cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
                    on_attach = on_attach,
                    settings = {
                        Lua = {
                            runtime = {
                                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                                version = 'LuaJIT',
                                -- Setup your lua path
                                path = vim.split(package.path, ';')
                            },
                            diagnostics = {
                                -- Get the language server to recognize the `vim` global
                                globals = {'vim', 'use'}
                            },
                            workspace = {
                                -- Make the server aware of Neovim runtime files
                                library = {
                                    [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                                    [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
                                }
                            }
                        }
                    },
                    capabilities = capabilities
                }
            })
            lspconfig.sumneko_lua.setup(luadev)

            lspconfig.efm.setup {
                on_attach = on_attach,
                init_options = {documentFormatting = true},
                filetypes = {"lua"},
                settings = {
                    rootMarkers = {".git/"},
                    languages = {
                        lua = {
                            {
                                formatCommand = "lua-format -i --column-limit=120", -- --no-keep-simple-function-one-line --no-break-after-operator --column-limit=150 --break-after-table-lb",
                                formatStdin = true
                            }
                        }
                    }
                }
            }

            local home = os.getenv('HOME')

            local jar_patterns = {
                home ..
                    '/.local/src/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
                home .. '/.local/src/vscode-java-test/server/*.jar'
            }

            local bundles = {}
            for _, jar_pattern in ipairs(jar_patterns) do
                for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
                    if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') then
                        table.insert(bundles, bundle)
                    end
                end
            end

            local extendedClientCapabilities = jdtls.extendedClientCapabilities
            extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

            function _G.jdtls_start_or_attach()
                local config = {
                    cmd = {
                        'jdtls.sh', home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
                    },
                    flags = {allow_incremental_sync = true, server_side_fuzzy_completion = true},
                    capabilities = {
                        workspace = {configuration = true},
                        textDocument = {completion = {completionItem = {snippetSupport = true}}}
                    },
                    on_attach = on_attach,
                    init_options = {bundles = bundles, extendedClientCapabilities = extendedClientCapabilities},
                    settings = {
                        java = {
                            signatureHelp = {enabled = true},
                            contentProvider = {preferred = 'fernflower'},
                            format = {insertSpaces = true, tabSize = 4},
                            completion = {
                                favoriteStaticMembers = {
                                    "org.hamcrest.MatcherAssert.assertThat", "org.hamcrest.Matchers.*",
                                    "org.hamcrest.CoreMatchers.*", "org.junit.jupiter.api.Assertions.*",
                                    "java.util.Objects.requireNonNull", "java.util.Objects.requireNonNullElse",
                                    "org.mockito.Mockito.*"
                                }
                            },
                            sources = {organizeImports = {starThreshold = 9999, staticStarThreshold = 9999}},
                            codeGeneration = {
                                toString = {
                                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                                }
                            },
                            configuration = {
                                runtimes = {
                                    {
                                        name = 'JavaSE-11',
                                        path = home .. '/.sdkman/candidates/java/11.0.11-zulu/',
                                        default = true
                                    }
                                    -- {name = 'JavaSE-1.8', path = home .. '/.sdkman/candidates/java/8.0.292-zulu'}
                                }
                            }
                        }
                    }
                }
                config.on_init = function(client, _)
                    client.notify('workspace/didChangeConfiguration', {settings = config.settings})
                end

                local finders = require 'telescope.finders'
                local sorters = require 'telescope.sorters'
                local actions = require 'telescope.actions'
                local pickers = require 'telescope.pickers'
                require('jdtls.ui').pick_one_async = function(items, prompt, label_fn, cb)
                    local opts = {}
                    pickers.new(opts, {
                        prompt_title = prompt,
                        finder = finders.new_table {
                            results = items,
                            entry_maker = function(entry)
                                return {value = entry, display = label_fn(entry), ordinal = label_fn(entry)}
                            end
                        },
                        sorter = sorters.get_generic_fuzzy_sorter(),
                        attach_mappings = function(prompt_bufnr)
                            actions.select_default:replace(function()
                                local selection = actions.get_selected_entry(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                cb(selection.value)
                            end)
                            return true
                        end
                    }):find()
                end

                jdtls.start_or_attach(config)
            end
        end
    }
end)

if install_pkgs then vim.cmd('PackerSync') end
