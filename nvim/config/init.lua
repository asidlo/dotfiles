-- Settings
vim.opt.lazyredraw = true
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
        {[[BufWritePre *.go lua vim.lsp.buf.formatting()]]},
        {[[BufWritePre *.go lua require('lsp.gopls').goimports(1000)]]},
        {[[FileType cpp setlocal makeprg=clang++\ -Wall\ -std=c++17]]},
        {[[FileType c,cpp setlocal formatprg=clang-format commentstring=\/\/\ %s]]},
        {[[BufEnter *gitconfig setlocal filetype=gitconfig]]}, {[[FileType gitcommit setlocal spell]]}
    },
    file_history = {{[[BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]}},
    dracula_customization = {
        {[[ColorScheme dracula highlight SpellBad gui=undercurl]]},
        {[[ColorScheme dracula highlight DraculaDiffDelete guibg=DraculaFg]]},
        {[[ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline]]}
    },
    lsp_settings = {
        {[[BufReadCmd jdt://* lua require('lsp.jdtls').open_jdt_link(vim.fn.expand('<amatch>'))]]},
        -- {"FileType java lua require('config.lsp').setup_jdtls()"},
        {
            [[CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs 
                :lua require'lsp_extensions'.inlay_hints{ prefix = '-> ', highlight = 'Comment', enabled = {'TypeHint', 'ChainingHint', 'ParameterHint'} }]]
        }
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
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
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

    use {'folke/which-key.nvim', config = function() require('config.whichkey') end}
    use {
        'neovim/nvim-lspconfig',
        requires = {
            {'nvim-lua/lsp_extensions.nvim'}, {'folke/lua-dev.nvim'}, {'onsails/lspkind-nvim'},
            {'mfussenegger/nvim-jdtls'}, {'mfussenegger/nvim-dap'}, {'ray-x/lsp_signature.nvim'},
            {'glepnir/lspsaga.nvim'}
        },
        config = function() require('config.lsp').setup_lspconfig() end
    }
    use {'glepnir/galaxyline.nvim', branch = 'main', config = function() require('config.statusline') end}
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function() require('config.tree') end
    }
    use {'simrat39/symbols-outline.nvim', config = function() require('config.outline') end}
    use {
        'L3MON4D3/LuaSnip',
        requires = {'rafamadriz/friendly-snippets'},
        config = function() require('config.snips') end
    }
    use {'hrsh7th/nvim-compe', requires = {'L3MON4D3/LuaSnip'}, config = function() require('config.compe') end}
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        requires = {'nvim-treesitter/nvim-treesitter-textobjects'},
        config = function() require('config.treesitter') end
    }
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}},
        config = function() require('config.telescope') end
    }
    use {
        'folke/trouble.nvim',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function() require('config.trouble') end
    }
    use {'norcalli/nvim-colorizer.lua', config = function() require('colorizer').setup() end}
    use {'b3nj5m1n/kommentary', config = function() require('config.kommentary') end}
    use {
        'folke/todo-comments.nvim',
        requires = {'nvim-lua/plenary.nvim'},
        config = function() require('config.todo') end
    }
    use {
        'lewis6991/gitsigns.nvim',
        requires = {'nvim-lua/plenary.nvim'},
        config = function() require('gitsigns').setup() end
    }
    use {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            -- vim.g.indentLine_enabled = 1
            vim.g.indent_blankline_char = "▏"
            vim.g.indent_blankline_filetype_exclude = {"help", "terminal", "dashboard"}
            vim.g.indent_blankline_buftype_exclude = {"terminal"}
            vim.g.indent_blankline_show_trailing_blankline_indent = false
            vim.g.indent_blankline_show_first_indent_level = false
            vim.g.indent_blankline_use_treesitter = true
        end
    }
end)
