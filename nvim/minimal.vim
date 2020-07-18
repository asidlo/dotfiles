if empty(glob(stdpath('data') . '/site/autoload/plug.vim'))
  silent execute '!curl -fLo ' . expand(stdpath('data') . '/site/autoload/plug.vim') . ' --create-dirs ' .
    \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand(stdpath('data') . '/plugged'))
  Plug 'dracula/vim', { 'as': 'dracula' }
call plug#end()

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

set textwidth=119
set mouse=a
set tabstop=4
set shiftwidth=4

try
  let g:dracula_inverse = 0
  colorscheme dracula
catch
  colorscheme default
endtry

augroup dracula_customization
  autocmd!
  autocmd ColorScheme dracula highlight SpellBad gui=undercurl
  autocmd ColorScheme dracula highlight Search
        \ guibg=NONE guifg=Yellow
        \ gui=underline term=underline cterm=underline
augroup END

augroup filetype_settings
  autocmd!
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2
  autocmd FileType c setlocal tabstop=4 shiftwidth=4
  autocmd FileType markdown setlocal textwidth=79
  autocmd TermOpen,BufEnter term://* startinsert!
  autocmd TermOpen,BufEnter term://* setlocal nonumber norelativenumber
augroup END
