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
set completeopt=menuone,noinsert,noselect
set clipboard=unnamed
set wildmode=longest:full,full
set wildmenu
set cmdheight=1
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

let g:netrw_dirhistmax = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

" Use a line cursor within insert mode and a block cursor everywhere else.
"
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

packadd cfilter
runtime ftplugin/man.vim

augroup file_history
        autocmd!
        " Return to last edit position when opening files (You want this!)
        autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

try
        packadd! dracula
        syntax enable
        colorscheme dracula
        let g:dracula_inverse = 0
        let g:dracula_colorterm = 0
        let g:dracula_italic = 0
        colorscheme dracula

        augroup dracula_customization
                autocmd!
                autocmd ColorScheme dracula highlight SpellBad gui=undercurl
                autocmd ColorScheme dracula highlight Search ctermbg=NONE guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline
        augroup END
catch
        colorscheme torte
endtry

let mapleader = ' '

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
