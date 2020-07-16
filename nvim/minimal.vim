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

let g:dracula_inverse = 0

try
  colorscheme dracula
catch
  colorscheme default
endtry

highlight SpellBad gui=undercurl
highlight Search
      \ guibg=NONE guifg=Yellow
      \ gui=underline term=underline cterm=underline 

augroup filetype_settings
  autocmd!
  autocmd Filetype vim setlocal tabstop=2 shiftwidth=2
  autocmd Filetype c setlocal tabstop=4 shiftwidth=4
  autocmd Filetype markdown setlocal textwidth=79
  autocmd TermOpen,BufEnter term://* startinsert!
augroup END
