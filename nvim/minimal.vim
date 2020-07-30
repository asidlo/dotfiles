"==============================================================================
" Author: Andrew Sidlo
" Description: Neovim minimal configuration file
"==============================================================================
" Section: VARIABLES {{{
"==============================================================================
let g:is_win = has('win32') || has('win64')
let g:is_linux = has('unix') && !has('macunix')
let g:is_nvim = has('nvim')
let g:is_gui = has('gui_running')

" Vim on windows doesn't have uname so results in error message even though we
" already know its not macos
if !g:is_nvim && g:is_win
  let g:is_mac = 0
else
  " Has some issues with vim detecting macunix/mac
  let g:is_mac = has('macunix') || substitute(system('uname -s'), '\n', '', '') == 'Darwin'
endif

let mapleader = ','

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
  Plug 'itchyny/lightline.vim'

  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-unimpaired'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-dispatch'

  Plug 'airblade/vim-rooter'
  Plug 'airblade/vim-gitgutter'
  Plug 'rhysd/git-messenger.vim'

  Plug 'jiangmiao/auto-pairs'
  Plug 'vim-scripts/ReplaceWithRegister'

  " Follow symlinks
  Plug 'moll/vim-bbye'
  Plug 'aymericbeaumet/vim-symlink'
call plug#end()
" }}}
" Section: SETTINGS {{{
"==============================================================================
set smartindent
set expandtab
set relativenumber
set splitbelow
set splitright
set termguicolors
set nomodeline
set autowriteall
set nobackup
set nowritebackup
set noswapfile
set linebreak
set smartcase
set undofile
set noshowmode
set hidden

set textwidth=119
set mouse=a
set tabstop=4
set shiftwidth=4
set completeopt=menuone,longest
set clipboard=unnamed
set wildmode=longest:full,full
set updatetime=100
set signcolumn=yes
set cmdheight=2

" Look for tags file in current buffer dir, then in the current dir, then use stdlibs
" Generated by using the following:
" $ ctags -R -f ~/.local/share/nvim/include/systags /usr/include /usr/local/include
set tags=./tags,tags,~/.local/share/nvim/include/systags

set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
"}}}
" Plugin: LIGHTLINE {{{
"==============================================================================
let g:lightline = { 'colorscheme': 'dracula' }
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
" Settings: NETRW {{{
"==============================================================================
let g:netrw_dirhistmax = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_liststyle = 3

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
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2 foldmethod=marker
  autocmd FileType json syntax match Comment +\/\/.\+$+
  autocmd FileType json setlocal commentstring=//\ %s
  autocmd FileType xml setlocal foldmethod=indent foldlevelstart=999 foldminlines=0
  autocmd FileType markdown setlocal textwidth=79 tabstop=2 shiftwidth=2
  autocmd FileType zsh setlocal foldmethod=marker tabstop=4 shiftwidth=4
  autocmd FileType java,groovy setlocal tabstop=4 shiftwidth=4 expandtab colorcolumn=120
  autocmd BufEnter *.jsh setlocal filetype=java
  autocmd FileType java,groovy setlocal tabstop=4 shiftwidth=4 expandtab colorcolumn=120

  autocmd FileType c
        \ setlocal tabstop=4 shiftwidth=4
        \ formatprg=clang-format\ -style=file\ --fallback-style=Microsoft
        \ textwidth=80
        \ cindent cinoptions=:0,l1,t0,g0,(0
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