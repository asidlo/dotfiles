"Author  : Andrew Sidlo
"Updated : April 14, 2019

" Set to auto read when a file is changed from the outside
set autoread

"Movement
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" For regular expressions turn magic on
set magic

" Section: Leader {{{
"==============================================================================
" Leader Mapping
"==============================================================================
let mapleader=","

"}}}
" Section: UI {{{
"==============================================================================
" Lines
"==============================================================================
" Add line numbers
set number

" Disable line wrapping
set nowrap

" Add 80, 120 line columns
set colorcolumn=80,120

"Always show current position
set ruler

"==============================================================================
" Command Bar 
"==============================================================================
" Height of the command bar
set cmdheight=1

"==============================================================================
" Margins
"==============================================================================
" Add a bit extra margin to the left
set foldcolumn=2

"==============================================================================
" Misc
"==============================================================================
" Don't redraw while executing macros (good performance config)
set lazyredraw 

"==============================================================================
" Matching Pairs
"==============================================================================
" Show matching brackets when text indicator is over them
set showmatch 

" How many tenths of a second to blink when matching brackets
set mat=2

"==============================================================================
" Status Line
"==============================================================================
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

"==============================================================================
" Sound
"==============================================================================
" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Properly disable sound on errors on MacVim
if has("gui_macvim")
    autocmd GUIEnter * set vb t_vb=
endif

"==============================================================================
" Colors
"==============================================================================
syntax enable
colorscheme jellybeans
set background=dark

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

"==============================================================================
" Font/Encodings
"==============================================================================
" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

"==============================================================================
" Notes/Tips
"==============================================================================
"Increase font size (iterm)
"cmd,shift,+

"Decrease font size (iterm)
"cmd,shift,-

"Make font normal (iterm)
"cmd,0

"}}}
" Section: Vimrc {{{
"==============================================================================
" Vimrc
"==============================================================================
"Reload vimrc
nnoremap confr :source $MYVIMRC<cr>

"Edit vimrc
nnoremap confe :e ~/.vimrc<cr>

"}}}
" Section: Escape {{{

"Map jj to exit edit mode while in edit mode
inoremap jj <Esc>

"<Ctrl+c> also exits insert mode

"}}}
" Section: Buffers {{{
" A buffer becomes hidden when it is abandoned
set hid

"Close the current buffer
map <leader>bd :bd<cr>

"Close all the buffers
map <leader>ba :bufdo bd<cr>

"Open scratch buffer
map <leader> bn :e ~/buffer<cr>
map <leader> bm :e ~/buffer.md<cr>

"https://stackoverflow.com/questions/1269603/to-switch-from-vertical-split-to-horizontal-split-fast-in-vim
"Changed tv and th for **To Vertical** and **To Horizontal**
"Horizontal buffer to vertical
nmap <leader>tv <c-w>t<c-w>H

"Vertical buffer to horizontal
nmap <leader>th <c-w>t<c-w>K

"https://vim.fandom.com/wiki/Fast_window_resizing_with_plus/minus_keys
"+ increases vertical buffer, - decreases
if bufwinnr(1)
  map + <C-W>+
  map - <C-W>-
endif

"Alt + Shift + > increases buffer width +1
"Alt + Shift + < decreases buffer width -1
nmap > :vertical res +1<Enter>
nmap < :vertical res -1<Enter>


" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>


" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"Splitting buffers
"https://vim.fandom.com/wiki/Buffers
"<C-w>s -> Horizontal split
"<C-w>v -> Vertical split

"Closing buffers
"<C-w>c -> closes current buffer

"}}}
"Folds {{{

"https://vim.fandom.com/wiki/Make_views_automatic
"Save folds in between buffer sessions
"au BufWinLeave * mkview
"au BufWinEnter * silent loadview
"TODO - Figure out how to make this work when closing all buffers, and opening
"	new one from no name buffer via confe

"https://vim.fandom.com/wiki/Folding
"Toggle fold
"za

"Open fold
"zo

"Close fold
"zc

"Open all folds
"zR

"Close all folds
"zM

"}}}
"Refactoring {{{

"Go back to visual mode after indenting
vnoremap < <gv
vnoremap > >gv


" Use alt+j/k to move line down/up
" https://vim.fandom.com/wiki/Moving_lines_up_or_down
" https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
  nmap <D-j> <M-j>
  nmap <D-k> <M-k>
  vmap <D-j> <M-j>
  vmap <D-k> <M-k>
endif

"}}}
"Terminal {{{

"Open terminal on the bottom
nnoremap <leader>t :wincmd b \| bel terminal<cr>

"}}}
"Navigation {{{

"Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

"}}}
" Section: Saving/Backups {{{

" Quick Saving
nmap <leader>w :w<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
command W w !sudo tee % > /dev/null

" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

"ZZ saves and quits

"}}}
"Syntax {{{

"Use nxlog syntax when opening log files
"au BufRead *.log set filetype=nxlog

"https://github.com/tetsuo13/vim-log4j
"autocmd BufRead,BufNewFile *.log set syntax=log4j
au BufRead,BufNewFile *.log set syntax=log

"}}}
" Section: Plugins {{{

"Enable filetype plugins
filetype plugin on
filetype indent on

"}}}
" Section: Text/Tab/Indent {{{


" Linebreak on 500 characters
set lbr
set tw=500

set wrap "Wrap lines

" Clear till end of line
" c$

" Delete till end of line
" d$

" }}}

" Section: Search {{{
"==============================================================================
" Search
"==============================================================================
" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch 

" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
map <space> /

if has('mac') || has('macunix')
  map <c-@> ?
else
  map <c-space> ?
endif

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" }}}
" Section: Tabs {{{
"==============================================================================
" Tabs
"==============================================================================
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=2
set tabstop=2

set ai "Auto indent
set si "Smart indent

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
map <leader>t<leader> :tabnext

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Show tab number only if more than 1
set stal=1

" TODO - Make a GoToTab function and create a command for tg

" }}}
" Section: Spellcheck {{{
"==============================================================================
" Spellcheck
"==============================================================================
" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Navigate to Next spell error
map <leader>sn ]s

" Naviate to previous spell error
map <leader>sp [s

" Toggle spell error highlight
map <leader>sa zg

" Make suggestions
map <leader>s? z=

" }}}
" Section: History {{{
"==============================================================================
" History
"==============================================================================
" Sets how many lines of history VIM has to remember
set history=500

"==============================================================================
" Undo
"==============================================================================
" Persistant undo, allowing you to undo even after closing a buffer
try
    set undodir=~/.vim/tmp/undodir
    set undofile
catch
endtry

" }}}
" Section: Commandline {{{
"==============================================================================
" Navigation
"==============================================================================
" Bash like keys for the command line
cnoremap <C-A>		<Home>
cnoremap <C-E>		<End>
cnoremap <C-K>		<C-U>

cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

"==============================================================================
" WildMenu
"==============================================================================
" Turn on the Wild menu
"https://stackoverflow.com/questions/9511253/how-to-effectively-use-vim-wildmenu
set wildmenu
set wildmode=longest:full,full

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" }}}
" Section: Autocomplete {{{
"==============================================================================
" Date
"==============================================================================
" Add date -> type XDATE lowercase followed by a char will autofill the date
iab xdate <c-r>=strftime("%d/%m/%y %H:%M:%S")<cr>

" }}}
" Section: Plugins {{{
"==============================================================================
" NerdTree
"==============================================================================
let g:NERDTreeWinPos = "left"
let NERDTreeShowHidden=0
let NERDTreeIgnore = ['\.pyc$', '__pycache__']
let g:NERDTreeWinSize=35
map <leader>nn :NERDTreeToggle %<cr>
map <leader>nb :NERDTreeFromBookmark<Space>
map <leader>nf :NERDTreeFind<cr>

" }}}
" Section: Functions {{{
"==============================================================================
" Selection
"==============================================================================
function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("Ack '" . l:pattern . "' " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

"==============================================================================
" Mode Checks
"==============================================================================
" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction
" }}}

"This line closes all folds in this file on start.
"Preceding space is important, removing will make it not work.
" vim:foldmethod=marker:foldlevel=0
