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
vim.opt.completeopt = { 'menuone' ,'noselect' }
vim.opt.clipboard = 'unnamed'
vim.opt.wildmode = { 'longest:full', 'full' }
vim.opt.updatetime = 300
vim.opt.cmdheight = 2
vim.opt.shortmess:append('c')
vim.opt.wildignore = { '*.o', '*~', '*.pyc', '*.class', '*/.git/*', '*/.hg/*', '*/.svn/*', '*/.DS_Store' }
vim.opt.timeoutlen = 500
vim.opt.listchars = { tab = '>-', trail = '-', nbsp = '+' }
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

vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.colors_name = 'dracula'
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.mapleader = ','

vim.g.markdown_fenced_languages = {'bash', 'json', 'javascript', 'python', 'java', 'groovy', 'go', 'rust'}

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
		{[[FileType markdown setlocal textwidth=79 expandtab tabstop=2 shiftwidth=2 ]]},
		{[[FileType text,asciidoc setlocal textwidth=79 expandtab tabstop=4 shiftwidth=4 spell]]},
		{"FileType markdown nmap ]] :execute '/^--\\+' <bar> :noh<CR>"},
		{"FileType markdown nmap [[ :execute '?^--\\+' <bar> :noh<CR>"},
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
	-- Should have packer in separate file and require it here, then run PackerSync
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

	use {'tpope/vim-commentary'}
	use {'tpope/vim-unimpaired'}
	use {'tpope/vim-repeat'}
	use {'tpope/vim-surround'}
	use {'tpope/vim-dispatch'}
	use {'tpope/vim-obsession'}
	use {'tpope/vim-fugitive', config = "require('config.fugitive')"}
	use {'airblade/vim-rooter'}
	use {'airblade/vim-gitgutter', config = "require('config.gitgutter')"}
	use {'rhysd/git-messenger.vim'}
	use {'moll/vim-bbye'}
	use {'aymericbeaumet/vim-symlink'}

	use { 'folke/which-key.nvim', config = "require('config.whichkey')" }
	use { 'neovim/nvim-lspconfig',
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
		'glepnir/galaxyline.nvim', branch = 'main',
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
		requires = { 'norcalli/snippets.nvim' },
		config = "require('config.compe')"
	}
	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		requires = {'nvim-treesitter/nvim-treesitter-textobjects'},
		config = "require('config.treesitter')"
	}
	use {
		'nvim-telescope/telescope.nvim',
		requires = {
			{'nvim-lua/popup.nvim'},
			{'nvim-lua/plenary.nvim'},
		},
		config = "require('config.telescope')"
	}
	use {
		"folke/trouble.nvim",
		requires = {"kyazdani42/nvim-web-devicons"},
		config = 'require("trouble").setup()'
	}
	use { 'norcalli/nvim-colorizer.lua', config = "require('colorizer').setup()" }
	use { 'sheerun/vim-polyglot' }
end)
