"==============================================================================
" Author: Andrew Sidlo
" Description: Vim minimal configuration file
"==============================================================================
" Section: PLUGINS {{{
"==============================================================================
if empty(glob('~/.vim/autoload/plug.vim'))
	silent execute '!curl -fLo ' . expand('~/.vim/autoload/plug.vim') . ' --create-dirs ' .
		\ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/.vim/plugged'))
	Plug 'dracula/vim', { 'as': 'dracula' }
	Plug 'itchyny/lightline.vim'

	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-commentary'
	Plug 'tpope/vim-unimpaired'
	Plug 'tpope/vim-repeat'
	Plug 'tpope/vim-surround'

	Plug 'airblade/vim-rooter'
	Plug 'airblade/vim-gitgutter'
	Plug 'rhysd/git-messenger.vim'

	Plug 'vim-scripts/ReplaceWithRegister'
	Plug 'sheerun/vim-polyglot'

	" Follow symlinks
	Plug 'moll/vim-bbye'
	Plug 'aymericbeaumet/vim-symlink'
call plug#end()

packadd cfilter
runtime ftplugin/man.vim

" }}}
" Section: SETTINGS {{{
"==============================================================================
set nocompatible
set list
set listchars=tab:>-,trail:-
set smarttab
set smartcase
set nowrap
set linebreak
set number
set relativenumber
set splitbelow
set splitright
set autowriteall
set noshowmode
set nobackup
set nowritebackup
set noswapfile
set autoread
set autowrite
set hidden
set novisualbell
set belloff=all
set scrolloff=0
set laststatus=2
set mouse=a
set completeopt=menuone,noinsert,noselect
set clipboard=unnamed
set wildmode=longest:full,full
set wildmenu
set cmdheight=2

set hlsearch
set incsearch
set showmatch

set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store

set undofile
set undodir=~/.vim/undo

set cscopetag
set cscopeverbose

set termguicolors
set t_Co=256

" }}}
" Plugin: LIGHTLINE {{{
"==============================================================================
let g:lightline = { 'colorscheme': 'dracula' }

" }}}
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

" }}}
" Plugin: FUGITIVE {{{
"==============================================================================
nnoremap <Leader>gs :G status -s<CR>
nnoremap <Leader>gl :G log --oneline<CR>
nnoremap <Leader>gb :!git branch -a<CR>
nnoremap <Leader>gd :G diff<CR>

" }}}
" Settings: NETRW {{{
"==============================================================================
let g:netrw_dirhistmax = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

" }}}
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
	autocmd FileType vim setlocal tabstop=2 shiftwidth=2 foldmethod=marker
	autocmd FileType json syntax match Comment +\/\/.\+$+
	autocmd FileType json setlocal commentstring=//\ %s
	autocmd FileType xml setlocal foldmethod=indent foldlevelstart=999 foldminlines=0
	autocmd FileType markdown,text setlocal textwidth=79 tabstop=2 shiftwidth=2
	autocmd FileType zsh setlocal foldmethod=marker tabstop=4 shiftwidth=4

	autocmd FileType java,groovy setlocal tabstop=4 shiftwidth=4 colorcolumn=120
	autocmd BufEnter *.jsh setlocal filetype=java
	autocmd FileType java,groovy setlocal tabstop=4 shiftwidth=4 colorcolumn=120
	autocmd BufEnter *.java compiler javac

	" using cmake with 'build' as output directory
	" autocmd FileType c,cpp setlocal makeprg=make\ -C\ build\ -Wall\ -std=c++17
	autocmd FileType c,cpp setlocal makeprg=clang++\ -Wall\ -std=c++17 commentstring=//\ %s
	autocmd FileType c,cpp setlocal formatprg=clang-format 
	autocmd FileType c,cpp setlocal cindent cinoptions=:0,l1,t0,g0,(0 textwidth=80 tabstop=8 shiftwidth=8 softtabstop=8
	autocmd BufEnter *gitconfig setlocal filetype=gitconfig
augroup END

" }}}
" Settings: COLORSCHEME {{{
"==============================================================================
augroup dracula_customization
	autocmd!
	autocmd ColorScheme dracula highlight SpellBad gui=undercurl
	autocmd ColorScheme dracula highlight Search ctermbg=NONE guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline
augroup END

try
	let g:dracula_inverse = 0
	let g:dracula_colorterm = 0
	let g:dracula_italic = 0
	colorscheme dracula
catch
	colorscheme default
endtry

" }}}
"==============================================================================
let mapleader = ','

"Yank till end of line
nnoremap Y y$

" Center search hit on next
nnoremap n nzzzv
nnoremap N Nzzzv

" Move cusor by display lines when wrapping
" noremap <up> gk
" noremap <down> gj
" noremap j gj
" noremap k gk

" Change pwd to current directory
nnoremap <leader>cd :cd %:p:h<cr>

" Add date -> type XDATE lowercase followed by a char will autofill the date
iab tdate <c-r>=strftime("%Y/%m/%d %H:%M:%S")<cr>
iab ddate <c-r>=strftime("%Y-%m-%d")<cr>
cab ddate <c-r>=strftime("%Y_%m_%d")<cr>
iab sdate <c-r>=strftime("%A %B %d, %Y")<cr>

command! -bar -nargs=1 -complete=file WriteQF
	\ call writefile([json_encode(s:qf_to_filename(getqflist({'all': 1})))], <f-args>)

command! -bar -nargs=1 -complete=file ReadQF
	\ call setqflist([], ' ', json_decode(get(readfile(<f-args>), 0, '')))

" https://www.reddit.com/r/vim/comments/9iwr41/store_quickfix_list_as_a_file_and_load_it/
function! s:qf_to_filename(qf) abort
	for i in range(len(a:qf.items))
		let d = a:qf.items[i]
		if bufexists(d.bufnr)
			let d.filename = fnamemodify(bufname(d.bufnr), ':p')
		endif
		silent! call remove(d, 'bufnr')
		let a:qf.items[i] = d
	endfor
	return a:qf
endfunction
