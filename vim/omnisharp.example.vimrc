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

        Plug 'OmniSharp/omnisharp-vim'

        " Mappings, code-actions available flag and statusline integration
        Plug 'nickspoons/vim-sharpenup'

        " Linting/error highlighting
        Plug 'dense-analysis/ale'

        " Vim FZF integration, used as OmniSharp selector
        Plug 'junegunn/fzf'
        Plug 'junegunn/fzf.vim'

        " Autocompletion
        Plug 'prabirshrestha/asyncomplete.vim'

        " Statusline
        Plug 'maximbaz/lightline-ale'

        " Snippet support
        Plug 'sirver/ultisnips'
call plug#end()

try
    packadd cfilter
catch
endtry

try
    runtime ftplugin/man.vim
catch
endtry

" }}}
" Section: SETTINGS {{{
"==============================================================================
set nocompatible
set nolist
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
set clipboard=unnamed
set wildmode=longest:full,full
set wildmenu
set cmdheight=1
set signcolumn=yes

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
set encoding=utf-8
scriptencoding utf-8
set completeopt=menuone,noinsert,noselect,popuphidden
set backspace=indent,eol,start
set expandtab
set shiftround
set shiftwidth=4
set softtabstop=-1
set tabstop=8
set textwidth=80
set title
set nofixendofline
set nostartofline
set nonumber
set noruler
set updatetime=1000

filetype indent plugin on
if !exists('g:syntax_on') | syntax enable | endif

" Use a line cursor within insert mode and a block cursor everywhere else.
" Reference chart of values:
"   Ps = 0  -> blinking block.
"   Ps = 1  -> blinking block (default).
"   Ps = 2  -> steady block.
"   Ps = 3  -> blinking underline.
"   Ps = 4  -> steady underline.
"   Ps = 5  -> blinking bar (xterm).
"   Ps = 6  -> steady bar (xterm).
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

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
" Plugin: ALE {{{
let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_sign_info = '·'
let g:ale_sign_style_error = '·'
let g:ale_sign_style_warning = '·'

let g:ale_linters = { 'cs': ['OmniSharp'] }
" }}}
" Plugin: OmniSharp {{{
let g:OmniSharp_popup_position = 'peek'
if has('nvim')
  let g:OmniSharp_popup_options = {
  \ 'winblend': 30,
  \ 'winhl': 'Normal:Normal,FloatBorder:ModeMsg',
  \ 'border': 'rounded'
  \}
else
  let g:OmniSharp_popup_options = {
  \ 'highlight': 'Normal',
  \ 'padding': [0],
  \ 'border': [1],
  \ 'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
  \ 'borderhighlight': ['ModeMsg']
  \}
endif
let g:OmniSharp_popup_mappings = {
\ 'sigNext': '<C-n>',
\ 'sigPrev': '<C-p>',
\ 'pageDown': ['<C-f>', '<PageDown>'],
\ 'pageUp': ['<C-b>', '<PageUp>']
\}

let g:OmniSharp_want_snippet = 1

let g:OmniSharp_highlight_groups = {
\ 'ExcludedCode': 'NonText'
\}
" }}}
" Plugin: Asyncomplete {{{
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0
" }}}
" Plugin: Sharpenup {{{
" All sharpenup mappings will begin with `<Space>os`, e.g. `<Space>osgd` for
" :OmniSharpGotoDefinition
let g:sharpenup_create_mappings = 0
let g:sharpenup_statusline_opts = { 'Text': '%s (%p/%P)' }
let g:sharpenup_statusline_opts.Highlight = 0

augroup sharpenup_csharp_mappings
	autocmd!
	autocmd FileType cs nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
	autocmd FileType cs nmap <silent> <buffer> gt <Plug>(omnisharp_go_to_type_definition)
	autocmd FileType cs nmap <silent> <buffer> gu <Plug>(omnisharp_find_usages)
	autocmd FileType cs nmap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)
	autocmd FileType cs nmap <silent> <buffer> K <Plug>(omnisharp_documentation)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>pd <Plug>(omnisharp_preview_definition)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>pi <Plug>(omnisharp_preview_implementations)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>pt <Plug>(omnisharp_type_lookup)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>ss <Plug>(omnisharp_find_symbol)
  autocmd FileType cs nmap <silent> <buffer> <LocalLeader>st <Plug>(omnisharp_find_type)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>fu <Plug>(omnisharp_fix_usings)
	autocmd FileType cs nmap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
	autocmd FileType cs imap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
	autocmd FileType cs nmap <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)
	autocmd FileType cs nmap <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>sr <Plug>(omnisharp_global_code_check)
	autocmd FileType cs	nmap <silent> <buffer> <LocalLeader>ca <Plug>(omnisharp_code_actions)
	autocmd FileType cs xmap <silent> <buffer> <LocalLeader>ca <Plug>(omnisharp_code_actions)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>. <Plug>(omnisharp_code_action_repeat)
	autocmd FileType cs xmap <silent> <buffer> <LocalLeader>. <Plug>(omnisharp_code_action_repeat)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>cr <Plug>(omnisharp_rename)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>cf <Plug>(omnisharp_code_format)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>ors <Plug>(omnisharp_restart_server)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>oss <Plug>(omnisharp_start_server)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>osx <Plug>(omnisharp_stop_server)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>t <Plug>(omnisharp_run_test)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>xt <Plug>(omnisharp_run_test_no_build)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>T <Plug>(omnisharp_run_tests_in_file)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>xT <Plug>(omnisharp_run_tests_in_file_no_build)
	autocmd FileType cs nmap <silent> <buffer> <LocalLeader>dt <Plug>(omnisharp_debug_test)
	autocmd FileType cs	nmap <silent> <buffer> <LocalLeader>dxt <Plug>(omnisharp_debug_test_no_build)
augroup end

augroup OmniSharpIntegrations
  autocmd!
  autocmd User OmniSharpProjectUpdated,OmniSharpReady call lightline#update()
augroup END
" }}}
" Plugin: Lightline {{{
let g:lightline = {
\ 'colorscheme': 'dracula',
\ 'active': {
\   'right': [
\     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok'],
\     ['lineinfo'], ['percent'],
\     ['fileformat', 'fileencoding', 'filetype', 'sharpenup']
\   ]
\ },
\ 'inactive': {
\   'right': [['lineinfo'], ['percent'], ['sharpenup']]
\ },
\ 'component': {
\   'sharpenup': sharpenup#statusline#Build()
\ },
\ 'component_expand': {
\   'linter_checking': 'lightline#ale#checking',
\   'linter_infos': 'lightline#ale#infos',
\   'linter_warnings': 'lightline#ale#warnings',
\   'linter_errors': 'lightline#ale#errors',
\   'linter_ok': 'lightline#ale#ok'
  \  },
  \ 'component_type': {
  \   'linter_checking': 'right',
  \   'linter_infos': 'right',
  \   'linter_warnings': 'warning',
  \   'linter_errors': 'error',
  \   'linter_ok': 'right'
\  }
\}
" Use unicode chars for ale indicators in the statusline
let g:lightline#ale#indicator_checking = "\uf110 "
let g:lightline#ale#indicator_infos = "\uf129 "
let g:lightline#ale#indicator_warnings = "\uf071 "
let g:lightline#ale#indicator_errors = "\uf05e "
let g:lightline#ale#indicator_ok = "\uf00c "
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

" Use truecolor in the terminal, when it is supported
if has('termguicolors')
  set termguicolors
endif

set background=dark

try
	let g:dracula_inverse = 0
	let g:dracula_colorterm = 0
	let g:dracula_italic = 0
	colorscheme dracula
catch
	colorscheme torte
endtry

augroup ColorschemePreferences
  autocmd!
  " Link ALE sign highlights to similar equivalents without background colours
  autocmd ColorScheme * highlight link ALEErrorSign   WarningMsg
  autocmd ColorScheme * highlight link ALEWarningSign ModeMsg
  autocmd ColorScheme * highlight link ALEInfoSign    Identifier
augroup END
" }}}
" Settings: Mappings {{{
let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

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
" }}}
"==============================================================================
