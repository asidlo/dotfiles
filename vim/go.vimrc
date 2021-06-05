if empty(glob('~/.vim/autoload/plug.vim'))
	silent execute '!curl -fLo ' . expand('~/.vim/autoload/plug.vim') . ' --create-dirs ' .
		\ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/.vim/plugged'))
	Plug 'morhetz/gruvbox'
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

	Plug 'moll/vim-bbye'
	Plug 'aymericbeaumet/vim-symlink'

	Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
	Plug 'ctrlpvim/ctrlp.vim'
call plug#end()

packadd cfilter
runtime ftplugin/man.vim

set nocompatible
set list
set listchars=tab:>-,trail:-
set smarttab
set ignorecase
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
set backspace=indent,eol,start

set hlsearch
set incsearch
set showmatch

set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store

set undofile
set undodir=~/.vim/undo

filetype plugin indent on

set termguicolors

let mapleader = ','

nnoremap Y y$
nnoremap n nzzzv
nnoremap N Nzzzv

noremap <up> gk
noremap <down> gj
noremap j gj
noremap k gk

let g:netrw_dirhistmax = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

augroup file_history
	autocmd!
	" Return to last edit position when opening files (You want this!)
	autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

augroup gruvbox_custom
	autocmd!
	autocmd ColorScheme gruvbox highlight SpellBad gui=undercurl
	autocmd ColorScheme gruvbox highlight Search ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow gui=underline term=underline cterm=underline
	autocmd ColorScheme gruvbox highlight SignColumn ctermbg=NONE guibg=NONE
augroup END

colorscheme gruvbox
let g:lightline = { 'colorscheme': 'gruvbox' }

if executable('rg')
	set grepformat=%f:%l:%c:%m,%f:%l:%m
	set grepprg=rg\ -S\ --vimgrep\ --no-heading
	let g:ctrlp_user_command = 'rg %s --files --glob ""'
	let g:ctrlp_use_caching = 0
else
	let g:ctrlp_clear_cache_on_exit = 0
endif

let g:ctrlp_map = '<Leader>f'
nnoremap <Leader>e :CtrlPMRUFiles<CR>
nnoremap <Leader>b :CtrlPBuffer<CR>

let g:gitgutter_set_sign_backgrounds = 1
let g:gitgutter_preview_win_floating = 1

" For walkthrough, use the following github repo as example:
" - https://github.com/fatih/vim-go-tutorial#quick-setup
let g:go_auto_sameids = 1
let g:go_auto_type_info = 1
let g:go_list_type = "quickfix"

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1

" Open :GoDeclsDir with ctrl-g
nmap <C-g> :GoDeclsDir<cr>
imap <C-g> <esc>:<C-u>GoDeclsDir<cr>

augroup go
	autocmd!
	autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4
	autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
	autocmd FileType go nmap <leader>t  <Plug>(go-test)
	autocmd FileType go nmap <leader>r  <Plug>(go-run)
	autocmd FileType go nmap <Leader>d <Plug>(go-doc)
	autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)
	autocmd FileType go nmap <Leader>i <Plug>(go-info)
	autocmd FileType go nmap <Leader>l <Plug>(go-metalinter)
	autocmd FileType go nmap <Leader>v <Plug>(go-def-vertical)
	autocmd FileType go nmap <Leader>s <Plug>(go-def-split)
	autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
	autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
	autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
	autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
augroup END

" build_go_files is a custom function that builds or compiles the test file.
" It calls :GoBuild if its a Go file, or :GoTestCompile if it's a test file
function! s:build_go_files()
	let l:file = expand('%')
	if l:file =~# '^\f\+_test\.go$'
		call go#test#Test(0, 1)
	elseif l:file =~# '^\f\+\.go$'
		call go#cmd#Build(0)
	endif
endfunction
