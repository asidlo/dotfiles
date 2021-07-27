"==============================================================================
" Author: Andrew Sidlo
" Description: Vim minimal configuration file
"==============================================================================
" Section: VARIABLES {{{
let mapleader = ','

" }}}
" Section: PLUGINS {{{
"==============================================================================
if empty(glob('~/.vim/autoload/plug.vim'))
	silent execute '!curl -fLo ' . expand('~/.vim/autoload/plug.vim') . ' --create-dirs ' .
		\ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/.vim/plugged'))
	Plug 'dracula/vim', { 'as': 'dracula' }
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'ryanoasis/vim-devicons'

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
	Plug 'wincent/ferret'

	" Follow symlinks
	Plug 'moll/vim-bbye'
	Plug 'aymericbeaumet/vim-symlink'

	Plug 'scrooloose/nerdtree'
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

	" Plug 'SirVer/ultisnips'
	" Plug 'honza/vim-snippets'

	Plug 'junegunn/fzf'
	Plug 'junegunn/fzf.vim'
call plug#end()

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
" Plugin: FZF {{{
"==============================================================================
let g:fzf_action = {
	\ 'ctrl-s': 'split',
	\ 'ctrl-v': 'vsplit' }

nnoremap <Leader>N :Files<cR>
nnoremap <Leader>n :GFiles<cr>
nnoremap <Leader>b :Buffers<cr>
nnoremap <Leader>E :History<cr>
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
nmap * <Plug>(FerretAckWord)

" Need to use <C-U> to escape visual mode and not enter search
vmap * :<C-U>call <SID>ferret_vack()<CR>

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
nmap <S-F6> <Plug>(FerretAcks)

" }}}
" GIT-MESSENGER {{{
"==============================================================================
let g:git_messenger_no_default_mappings = v:true

nmap <leader>gm <Plug>(git-messenger)
" }}}
" VIM-DEVICONS {{{
"==============================================================================
"https://github.com/ryanoasis/vim-devicons/wiki/FAQ-&-Troubleshooting#how-do-i-solve-issues-after-re-sourcing-my-vimrc
if exists("g:loaded_webdevicons")
  call webdevicons#refresh()
endif

" }}}
" AIRLINE {{{
"==============================================================================
let g:airline_theme='dracula'

let g:airline_powerline_fonts = 1
" let g:airline_symbols_ascii = 1

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1

" Disable tagbar for performance
let g:airline#extensions#tagbar#enabled = 0

if !exists('g:airline_symbols')
let g:airline_symbols = {}
endif

" let g:airline_symbols.whitespace='_'
let g:airline_symbols.whitespace=''
let g:airline_symbols.linenr = ''
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.notexists = ' ??'

" let g:airline_symbols.space = "\ua0"

" powerline symbols
" https://www.nerdfonts.com/cheat-sheet
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
" let g:airline_symbols.branch = '@'
let g:airline_symbols.readonly = ''
" let g:airline_symbols.linenr = ''
" let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.dirty=' M'
" let g:airline_symbols.whitespace='/s'
" let g:airline_symbols.crypt='0x'
" let g:airline_symbols.notexists=' ?'

" let airline#extensions#ale#show_line_numbers = 0
" let g:airline#extensions#ale#warning_symbol = "\uf071 "
" let g:airline#extensions#ale#error_symbol = "\uf05e "
" let g:lightline#ale#indicator_checking = "\uf110"
" let g:lightline#ale#indicator_infos = "\uf129 "
" let g:lightline#ale#indicator_ok = "\uf00c"

let g:airline#extensions#default#section_truncate_width = {
	\ 'c': 50,
	\ }

let g:airline#extensions#tabline#fnamemod = ':t'

"Reduces the space occupied by section z
let g:airline_section_z = "%3p%% %l:%c"

" }}}
" NERDTREE {{{
"==============================================================================
let g:NERDTreeWinPos = "left"
let g:NERDTreeWinSize=35

" Prevent fluff from appearing in the file drawer
let NERDTreeIgnore=[
	\ '__pycache__', '^node_modules$', '\~$', '^\.git$', '^\.DS_Store$', '^\.vim$',
	\ '^\.meta$', '^\.settings$', '^\.classpath$', '^\.project$',
	\ '^\.gradle$', '^\.idea$', '^\.metadata$', '^/bin$', '^GPATH$', '^G.*TAGS$', '^tags$'
	\]

" Show hidden files in NERDTree
let NERDTreeShowHidden=1

" Ignore the help-instructions at the top of NERDTree
let NERDTreeMinimalUI=1

" Delete the NERDTree buffer when it's the only one left
let NERDTreeAutoDeleteBuffer=1

" Close automatically if nerd tree is only buffer open
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Dont focus Nerdtree on enter
" autocmd! VimEnter * NERDTree | wincmd w

let g:NERDTreeQuitOnOpen = 0

nnoremap yoe :NERDTreeToggle<cr>
nnoremap [oe :NERDTree<cr>
nnoremap ]oe :NERDTreeClose<cr>

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
	autocmd BufEnter gitconfig setlocal filetype=gitconfig
augroup END

" }}}
" Settings: COLORSCHEME {{{
"==============================================================================
augroup dracula_customization
	autocmd!
	autocmd ColorScheme dracula highlight SpellBad gui=undercurl
	autocmd ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline
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
