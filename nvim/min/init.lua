-- Settings
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.termguicolors = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.smartcase = true
vim.o.ignorecase = true
vim.o.showmode = false
vim.o.hidden = true
vim.o.autoread = true
vim.o.autowriteall = true
vim.o.mouse = 'a'
vim.o.completeopt = 'menuone,noselect'
vim.o.clipboard = 'unnamed'
vim.o.wildmode = 'longest:full,full'
vim.o.updatetime = 300
vim.o.cmdheight = 2
vim.o.shortmess = vim.o.shortmess .. 'c'
vim.o.wildignore = '*.o,*~,*.pyc,*.class,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store'
vim.o.timeoutlen = 500
vim.o.listchars = 'tab:>-,trail:-,nbsp:+'
vim.o.spellsuggest = '15'
vim.o.dictionary = '/usr/share/dict/words'

if vim.fn.executable('rg') then
    vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
    vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

vim.o.swapfile = false
vim.bo.swapfile = false
vim.o.undofile = true
vim.bo.undofile = true
vim.o.modeline = false
vim.bo.modeline = false
vim.o.smartindent = true
vim.bo.smartindent = true
vim.o.tabstop = 4
vim.bo.tabstop = 4
vim.o.shiftwidth = 4
vim.bo.shiftwidth = 4
vim.o.expandtab = true
vim.bo.expandtab = true

vim.wo.wrap = false
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.foldenable = false
vim.wo.signcolumn = 'yes'
vim.o.list = true
vim.wo.list = true

vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.colors_name = 'dracula'
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.mapleader = ','

--- Creates key mappings to reduce typing
---@param mode string 'n' | 'v' | 'i'...etc
---@param map string keys to be mapped
---@param key string
---@param opts any
function _G.set_keymap(mode, map, key, opts)
    if opts == nil then
        opts = {
            noremap = true,
            silent = true
        }
    end
    vim.api.nvim_set_keymap(mode, map, key, opts)
end

function _G.set_buf_keymap(buf, mode, map, key, opts)
    if opts == nil then
        opts = {
            noremap = true,
            silent = true
        }
    end
    vim.api.nvim_buf_set_keymap(buf, mode, map, key, opts)
end

function _G.replace_termcodes(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function _G.new_buf(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    local buf = vim.api.nvim_create_buf(true, true)
    local content = {}
    for _, obj in ipairs(objects) do
        for _, line in ipairs(vim.split(obj, '\n')) do
            table.insert(content, line)
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)
    vim.cmd('b ' .. buf)
end

function _G.lsp_clients()
    return vim.lsp.buf_get_clients()
end

function _G.has_document_symbol_support(client)
    return client.resolved_capabilities.document_symbol ~= nil
end

function _G.has_document_definition_support(client)
    return client.resolved_capabilities.textDocument_definition ~= nil
end

function _G.lsp_handlers()
    return vim.tbl_keys(vim.lsp.handlers)
end

function _G.is_buffer_empty()
    -- Check whether the current buffer is empty
    return vim.fn.empty(vim.fn.expand('%:t')) == 1
end

function _G.has_width_gt(cols)
    -- Check if the windows width is greater than a given number of columns
    return vim.fn.winwidth(0) / 2 > cols
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

-- http://lua-users.org/wiki/StringTrim #6
function _G.trim(s)
    if s == nil then
        return nil
    end
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
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
        {[[FileType markdown,text,asciidoc setlocal textwidth=79 spell]]},
        {[[FileType java,groovy setlocal foldlevel=2 colorcolumn=120 expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType rust setlocal expandtab tabstop=4 shiftwidth=4]]},
        {[[FileType go setlocal noexpandtab tabstop=4 shiftwidth=4]]},
        {[[FileType cpp setlocal makeprg=clang++\ -Wall\ -std=c++17]]},
        {[[FileType c,cpp setlocal formatprg=clang-format commentstring=\/\/\ %s]]},
        {[[BufEnter *gitconfig setlocal filetype=gitconfig]]},
        {[[FileType gitcommit setlocal spell]]}
    },
    file_history = {{[[BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]}},
    dracula_customization = {
        {[[ColorScheme dracula highlight SpellBad gui=undercurl]]},
        {[[ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline]]}
    },
    lsp_settings = {
        {[[BufAdd jdt://* call luaeval("require('lsp.jdtls').open_jdt_link(_A)", expand('<amatch>'))]]},
        {[[CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs :lua require'lsp_extensions'.inlay_hints{ prefix = '-> ', highlight = 'Comment', enabled = {'TypeHint', 'ChainingHint', 'ParameterHint'} }]]}
    }
}
nvim_create_augroups(autocmds)

set_keymap('n', 'Y', 'y$')
set_keymap('n', 'n', 'nzzzv')
set_keymap('n', 'N', 'Nzzzv')
set_keymap('n', '<Up>', 'gk')
set_keymap('n', '<Down>', 'gj')
set_keymap('n', 'j', 'gj')
set_keymap('n', 'k', 'gk')
set_keymap('n', '<Leader>cd', '<Cmd>cd %:p:h<CR>')
set_keymap('n', '<Leader>p', '<Cmd>lua stdout()<CR>')

--- Prints content of register to stdout. If register is null then '*' register is used
--- @param reg string register to print to stdout
function _G.stdout(reg)
    if reg == nil then
        reg = '*'
    end
    local num_spaces = tonumber(vim.o.tabstop)
    local cb = string.gsub(vim.fn.getreg(reg), '\t', string.rep(' ', num_spaces))
    print(cb)
end

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
    use {
        'dracula/vim',
        as = 'dracula'
    }
    use {'tpope/vim-commentary'}
    use {'tpope/vim-unimpaired'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-surround'}
    use {'tpope/vim-dispatch'}
    use {'tpope/vim-obsession'}
    use {
        'tpope/vim-fugitive',
        config = "require('config.fugitive')"
    }
    use {'airblade/vim-rooter'}
    use {
        'airblade/vim-gitgutter',
        config = "require('config.gitgutter')"
    }
    use {'rhysd/git-messenger.vim'}
    use {'vim-scripts/ReplaceWithRegister'}
    use {'moll/vim-bbye'}
    use {'aymericbeaumet/vim-symlink'}
    use {
        'folke/which-key.nvim',
        config = "require('config.whichkey')"
    }
    use {
        'neovim/nvim-lspconfig',
        requires = {
            {'nvim-lua/lsp_extensions.nvim'},
            {'folke/lua-dev.nvim'},
            {
                'glepnir/lspsaga.nvim',
                config = "require('config.lspsaga')"
            }
        },
        config = "require('config.lsp')"
    }
    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        requires = {'kyazdani42/nvim-web-devicons', opt = true},
        config = "require('config.statusline')"
    }
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = "require('config.tree')"
    }
    use {
        'simrat39/symbols-outline.nvim',
        config = "require('config.outline')"
    }
    use {
        'hrsh7th/nvim-compe',
        requires = {
            'norcalli/snippets.nvim',
        },
        config = "require('config.compe')"
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        requires = {'nvim-treesitter/nvim-treesitter-textobjects'},
        config = "require('config.treesitter')"
    }
    use {
        'plasticboy/vim-markdown',
        requires = {'godlygeek/tabular'},
        config = "require('config.markdown')"
    }
    use {
        'nvim-telescope/telescope.nvim',
        requires = {
            {'nvim-lua/popup.nvim'},
            {'nvim-lua/plenary.nvim'},
        },
        config = "require('config.telescope')"
    }
end)

vim.cmd('let g:nvim_tree_width_allow_resize = 1')
