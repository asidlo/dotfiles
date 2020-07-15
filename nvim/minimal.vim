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
set undodir=~/.config/nvim/undo
set tags+=~/.config/nvim/systags

augroup filetype_settings
  autocmd!
  autocmd Filetype vim setlocal tabstop=2 shiftwidth=2
  autocmd Filetype c setlocal tabstop=4 shiftwidth=4
  autocmd Filetype markdown setlocal textwidth=79
  autocmd TermOpen,BufEnter term://* startinsert!
augroup END
