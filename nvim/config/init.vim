"==============================================================================
" Author: Andrew Sidlo
" Description: Neovim configuration file
"==============================================================================
" Section: VARIABLES {{{
"==============================================================================
let mapleader = ','

lua require('util')

" }}}
" Section: PLUGINS {{{
"==============================================================================
if empty(glob(stdpath('data') . '/site/autoload/plug.vim'))
	silent execute '!curl -fLo ' . expand(stdpath('data') . '/site/autoload/plug.vim') . ' --create-dirs ' .
		\ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand(stdpath('data') . '/plugged'))
	Plug 'dracula/vim', { 'as': 'dracula' }
	Plug 'glepnir/galaxyline.nvim', {'branch': 'main'}

	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-commentary'
	Plug 'tpope/vim-unimpaired'
	Plug 'tpope/vim-repeat'
	Plug 'tpope/vim-surround'
	Plug 'tpope/vim-dispatch'
	Plug 'tpope/vim-obsession'

	Plug 'airblade/vim-rooter'
	Plug 'airblade/vim-gitgutter'
	Plug 'rhysd/git-messenger.vim'

	Plug 'vim-scripts/ReplaceWithRegister'

	" Follow symlinks
	Plug 'moll/vim-bbye'
	Plug 'aymericbeaumet/vim-symlink'

	" Note: ployglot changes tabstop to 2 from 8 default
	" Plug 'sheerun/vim-polyglot'
	Plug 'godlygeek/tabular'
	Plug 'plasticboy/vim-markdown'

	Plug 'wincent/ferret'

	Plug 'junegunn/fzf'
	Plug 'junegunn/fzf.vim'

	Plug 'kyazdani42/nvim-web-devicons'
	Plug 'kyazdani42/nvim-tree.lua'

	Plug 'nvim-lua/lsp_extensions.nvim'
	Plug 'neovim/nvim-lspconfig'

	Plug 'glepnir/lspsaga.nvim'

	Plug 'liuchengxu/vista.vim'

	Plug 'hrsh7th/nvim-compe'
	Plug 'norcalli/snippets.nvim'

	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'nvim-treesitter/nvim-treesitter-textobjects'

call plug#end()

" }}}
" Section: SETTINGS {{{
"==============================================================================
set number
set relativenumber
set splitbelow
set splitright
set termguicolors
set nomodeline
set nobackup
set nowritebackup
set noswapfile
set nowrap
set linebreak
set ignorecase
set smartcase
set undofile
set noshowmode
set hidden
set autoread
set autowriteall
set nofoldenable
set smartindent

set mouse=a
set completeopt=menuone,noselect
set shortmess+=c
set clipboard=unnamed
set wildmode=longest:full,full
set updatetime=300
set signcolumn=yes
set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
set listchars=tab:>-,trail:-,nbsp:+

"}}}
" Plugin: GITGUTTER {{{
"==============================================================================
let g:gitgutter_map_keys = 0

nnoremap ]h :GitGutterNextHunk<CR>
nnoremap [h :GitGutterPrevHunk<CR>

nmap <Leader>hs <Plug>(GitGutterStageHunk)
nmap <Leader>hu <Plug>(GitGutterUndoHunk)
nmap <Leader>hp <Plug>(GitGutterPreviewHunk)

omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)

"}}}
" Plugin: FUGITIVE {{{
"==============================================================================
nnoremap <Leader>gs :G status -s<CR>
nnoremap <Leader>gl :G log --oneline<CR>
nnoremap <Leader>gb :!git branch -a<CR>
nnoremap <Leader>gd :G diff<CR>

" }}}
" Plugin: VIM-MARKDOWN {{{
"==============================================================================
let g:vim_markdown_folding_style_pythonic = 1
let g:vim_markdown_override_foldtext = 0

" Dont insert indent when using 'o' & dont auto insert bullets on format
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" }}}
" Plugin: FZF {{{
"==============================================================================
let g:fzf_action = {
	\ 'ctrl-s': 'split',
	\ 'ctrl-v': 'vsplit' }

nnoremap <Leader>f :Files<cR>
nnoremap <Leader>n :GFiles<cr>
nnoremap <Leader>b :Buffers<cr>
nnoremap <Leader>e :History<cr>
nnoremap <Leader>x :Maps<cr>
nnoremap <Leader>X :Commands<cr>

" Dracula adds the CursorLine highlight to fzf
let g:fzf_colors =
	\ { 'fg': ['fg', 'Normal'],
	\ 'bg': ['bg', 'Normal'],
	\ 'hl': ['fg', 'Comment'],
	\ 'fg+': ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
	\ 'hl+': ['fg', 'Statement'],
	\ 'info': ['fg', 'PreProc'],
	\ 'border': ['fg', 'Ignore'],
	\ 'prompt': ['fg', 'Conditional'],
	\ 'pointer': ['fg', 'Exception'],
	\ 'marker': ['fg', 'Keyword'],
	\ 'spinner': ['fg', 'Label'],
	\ 'header': ['fg', 'Comment'] }

" }}}
" Plugin: FERRET {{{
"==============================================================================
" If you want to do a global replace, you need to search for the term to add it
" to the ferret quickfix, then all instances in the quickfix will be subject to
" the replacement matching when using FerretAcks
let g:FerretMap = 0

" Searches whole project, even through ignored files
nnoremap \ :Ack<space>

" Search for current word
nmap <F6> <Plug>(FerretAckWord)

" Need to use <C-U> to escape visual mode and not enter search
vmap <F6> :<C-U>call <SID>ferret_vack()<CR>

function! s:ferret_vack() abort
	let l:selection = s:get_visual_selection()
	for l:char in [' ', '(', ')']
		let l:selection = escape(l:selection, l:char)
	endfor
	execute ':Ack ' . l:selection
endfunction

" https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
function! s:get_visual_selection() abort
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		return ''
	endif
	let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	return join(lines, "\n")
endfunction

" Replace instances matching term in quickfix 'F19 == S-F7'
nmap <F18> <Plug>(FerretAcks)

" }}}
" Plugin: NVIM-TREESITTER {{{
"==============================================================================
lua require('config.treesitter')
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

" }}}
" Plugin: NVIM-TREE {{{
"==============================================================================
nnoremap <C-n> :NvimTreeToggle<CR>
let g:nvim_tree_width_allow_resize = 1

" }}}
" Plugin: GALAXYLINE {{{
"==============================================================================
lua require('config.galaxyline')

" }}}
" Plugin: LSP-CONFIG {{{
"==============================================================================
lua require('config.lsp')

" }}}
" Plugin: LSPSAGA {{{
"==============================================================================
lua require('config.lspsaga')

" }}}
" Plugin: NVIM-COMPE {{{
"==============================================================================
lua require('config.nvim-compe')

" }}}
" Plugin: VISTA {{{
"==============================================================================
" How each level is indented and what to prepend.
" This could make the display more compact or more spacious.
" e.g., more compact: ["▸ ", ""]
" Note: this option only works the LSP executives, doesn't work for `:Vista ctags`.
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]

" Executive used when opening vista sidebar without specifying it.
" See all the avaliable executives via `:echo g:vista#executives`.
let g:vista_default_executive = 'nvim_lsp'

" By default vista.vim never run if you don't call it explicitly.
"
" If you want to show the nearest function in your statusline automatically,
" you can add the following line to your vimrc
" autocmd VimEnter * call vista#RunForNearestMethodOrFunction()

" }}}
" Settings: NETRW {{{
"==============================================================================
let g:loaded_netrwPlugin = 1

" }}}
" Settings: NVIM {{{
"==============================================================================
" Disable python2, ruby, and node providers
let g:loaded_python_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0
let g:python3_host_prog = '/usr/bin/python3'

augroup nvim_settings
	autocmd!
	autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank()
	autocmd TermOpen,TermEnter term://* startinsert!
	autocmd TermEnter term://* setlocal nonumber norelativenumber signcolumn=no
augroup END

"}}}
" Settings: MISC {{{
"==============================================================================
augroup file_history
	autocmd!
	" Return to last edit position when opening files (You want this!)
	autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" }}}
" Settings: FILETYPES {{{
"==============================================================================
augroup filetype_settings
	autocmd!
	autocmd FileType vim setlocal tabstop=2 shiftwidth=2 foldmethod=marker foldenable
	autocmd FileType lua setlocal tabstop=2 shiftwidth=2
	autocmd FileType json syntax match Comment +\/\/.\+$+
	autocmd FileType json setlocal commentstring=//\ %s
	autocmd FileType xml setlocal foldmethod=indent foldlevelstart=999 foldminlines=0
	autocmd FileType markdown,text setlocal textwidth=79 tabstop=2 shiftwidth=2
	autocmd FileType zsh setlocal foldmethod=marker tabstop=4 shiftwidth=4
	autocmd BufEnter *.jsh setlocal filetype=java
	autocmd FileType java,groovy setlocal foldlevel=2 tabstop=4 shiftwidth=4 colorcolumn=120
	autocmd BufAdd jdt://* call luaeval("require('lsp.jdtls').open_jdt_link(_A)", expand('<amatch>')) 
	autocmd BufEnter gitconfig setlocal filetype=gitconfig

	autocmd CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs
		\ :lua require'lsp_extensions'.inlay_hints{ prefix = '', highlight = 'Comment', enabled = {'TypeHint', 'ChainingHint', 'ParameterHint'} }

	" using cmake with 'build' as output directory
	" autocmd FileType c,cpp setlocal makeprg=make\ -C\ build\ -Wall\ -std=c++17
	autocmd FileType c,cpp setlocal makeprg=clang++\ -Wall\ -std=c++17 commentstring=//\ %s
augroup END

"}}}
" Settings: COLORSCHEME {{{
"==============================================================================
augroup dracula_customization
	autocmd!
	autocmd ColorScheme dracula highlight SpellBad gui=undercurl
	autocmd ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline
augroup END

try
	let g:dracula_inverse = 0
	colorscheme dracula
catch
	colorscheme default
endtry

"}}}
"==============================================================================
"Yank till end of line
nnoremap Y y$

" Center search hit on next
nnoremap n nzzzv
nnoremap N Nzzzv

" Move cusor by display lines when wrapping
noremap <up> gk
noremap <down> gj
noremap j gj
noremap k gk

" Change pwd to current directory
nnoremap <leader>cd :cd %:p:h<cr>

" Search for current word but dont jump to next result
nnoremap * :let @/='\<<C-R>=expand("<cword>")<CR>\>'<CR>:set hls<CR>

" Add date -> type XDATE lowercase followed by a char will autofill the date
iab tdate <c-r>=strftime("%Y/%m/%d %H:%M:%S")<cr>
iab ddate <c-r>=strftime("%Y-%m-%d")<cr>
cab ddate <c-r>=strftime("%Y_%m_%d")<cr>
iab sdate <c-r>=strftime("%A %B %d, %Y")<cr>
