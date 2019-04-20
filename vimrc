"==============================================================================
" Author:  Andrew Sidlo
" Updated: April 14, 2019
"==============================================================================
" Section: Leader {{{
"==============================================================================
" Leader Mapping
"==============================================================================
let mapleader=","

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
" Section: Terminal {{{
"==============================================================================
" Open Terminal
"==============================================================================
"Open terminal on the bottom
nnoremap <leader>t :wincmd b \| bel terminal<cr>

"}}}
" Section: UI {{{
"==============================================================================
" Lines
"==============================================================================
" Add line numbers
set number

"Linenumbers are relative to current line
set relativenumber 

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

" Hide mode indicator in command bar, since its covered via lightline
set noshowmode

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
"set statusline=\%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

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
" Section: Syntax {{{
"==============================================================================
" Custom Syntax
"==============================================================================
"Use nxlog syntax when opening log files
"au BufRead *.log set filetype=nxlog

"https://github.com/tetsuo13/vim-log4j
"autocmd BufRead,BufNewFile *.log set syntax=log4j
au BufRead,BufNewFile *.log set syntax=log

"}}}
" Section: Buffers {{{
"==============================================================================
" Management 
"==============================================================================
" A buffer becomes hidden when it is abandoned
set hid

"Close the current buffer
map <leader>bd :bd<cr>

"Close all the buffers
map <leader>ba :bufdo bd<cr>

"Closing buffers
"<C-w>c -> closes current buffer

"Open scratch buffer
map <leader> bn :e ~/buffer<cr>
map <leader> bm :e ~/buffer.md<cr>


"==============================================================================
" View
"==============================================================================
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

"==============================================================================
" Splits
"==============================================================================
"https://vim.fandom.com/wiki/Buffers
"<C-w>s -> Horizontal split
"<C-w>v -> Vertical split
"
"New splits below, not above
set splitbelow 

"New splits on the right, not left
set splitright 

"==============================================================================
" Misc
"==============================================================================
" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"}}}
" Section: Folds {{{

" https://vim.fandom.com/wiki/Make_views_automatic
" Save folds in between buffer sessions
" au BufWinLeave * mkview
" au BufWinEnter * silent loadview
" TODO - Figure out how to make this work when closing all buffers, and opening
"	new one from no name buffer via confe

"==============================================================================
" Commands
"==============================================================================
"https://vim.fandom.com/wiki/Folding

" | Command | Description      |
" | za      | Toggle fold      |
" | zo      | Open fold        |
" | zc      | Close fold       |
" | zR      | Open all folds   |
" | zM      | Close all folds  |
" | zi      | Toggle all folds |

"}}}
" Section: Refactoring {{{

"==============================================================================
" Shift Text Block
"==============================================================================
"Go back to visual mode after indenting
vnoremap < <gv
vnoremap > >gv

"==============================================================================
" Move Text Block
"==============================================================================
" Use alt+j/k to move line down/up
" https://vim.fandom.com/wiki/Moving_lines_up_or_down
" https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
" Move a line of text using ALT+[jk] or Command+[jk] on mac
if has("mac") || has("macunix")
  nmap ∆ mz:m+<cr>`z
  nmap ˚ mz:m-2<cr>`z
  vmap ∆ :m'>+<cr>`<my`>mzgv`yo`z
  vmap ˚ :m'<-2<cr>`>my`<mzgv`yo`z
else
  nmap <A-j> mz:m+<cr>`z
  nmap <A-k> mz:m-2<cr>`z
  vmap <A-j> :m'>+<cr>`<my`>mzgv`yo`z
  vmap <A-k> :m'<-2<cr>`>my`<mzgv`yo`z
endif

" Make merging lines smarter when using <shift-j>
if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j
endif

"}}}
" Section: Navigation {{{
"==============================================================================
" Window Navigation
"==============================================================================
"Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Move to the first/last non-blank character on this line
map H ^
map L $

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

"}}}
" Section: Saving/Backups {{{
"==============================================================================
" Saving
"==============================================================================
" Quick Saving
nmap <leader>w :w<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
command W w !sudo tee % > /dev/null

" Set to auto read when a file is changed from the outside
set autoread

"==============================================================================
" Backups
"==============================================================================
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

"==============================================================================
" Notes/Tips
"==============================================================================
" ZZ saves and quits

"}}}
" Section: Plugins {{{
"==============================================================================
" Enable Plugins
"==============================================================================
"Enable filetype plugins
filetype plugin on
filetype indent on

"}}}
" Section: Text {{{
"==============================================================================
" Text Config
"==============================================================================
" Linebreak on 500 characters
set lbr
set tw=500
set wrap 

" How to represent non-printable characters
" In general, don't want tabs, so have them show up as special characters
set listchars=tab:>-,trail:·,extends:>,precedes:<
set list "turn the above on

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" For regular expressions turn magic on
set magic

"==============================================================================
" Notes/Tips
"==============================================================================
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

" Disable the netrw history file which is otherwise added to ~/.vim/.netrwhist
let g:netrw_dirhistmax = 0

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
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>

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
let g:NERDTreeWinSize=35

" Prevent fluff from appearing in the file drawer
let NERDTreeIgnore=['\.pyc$', '__pycache__', 'node_modules$', '\~$', '\.git$', '\.DS_Store$', '\.meta$']

" Show hidden files in NERDTree
let NERDTreeShowHidden=1

" Ignore the help-instructions at the top of NERDTree
let NERDTreeMinimalUI=1

" Delete the NERDTree buffer when it's the only one left
let NERDTreeAutoDeleteBuffer=1

map <leader>nn :NERDTreeToggle %<cr>
map <leader>nb :NERDTreeFromBookmark<Space>
map <leader>nf :NERDTreeFind<cr>
nmap <leader>n? :map <leader>n<cr>

"==============================================================================
" Fugitive
"==============================================================================
nmap <leader>gb :Gblame<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>gd :Gdiff<cr>
nmap <leader>gg :Ggrep
nmap <leader>gl :Glog<cr>
nmap <leader>gp :Git pull<cr>
nmap <leader>gP :Git push<cr>
nmap <leader>gs :Gstatus<cr>
nmap <leader>gw :Gbrowse<cr>
nmap <leader>g? :map <leader>g<cr>

"==============================================================================
" Tabularize
"==============================================================================
" NOTE:
"   - a = align
"   - t = table
if exists(":Tabularize")
  nmap <leader>a= :Tabularize /=<CR>
  vmap <leader>a= :Tabularize /=<CR>
  nmap <leader>a: :Tabularize /:\zs<CR>
  vmap <leader>a: :Tabularize /:\zs<CR>
  nmap <leader>at :Tabularize /\|<CR>
  vmap <leader>at :Tabularize /\|<CR>
  nmap <leader>a? :map <leader>a<cr>
endif

"==============================================================================
" Lightline
"==============================================================================
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['fugitive', 'readonly', 'filename', 'modified'] ],
      \   'right': [[ 'lineinfo' ], ['percent'], ['fileformat', 'fileencoding', 'filetype' ]]
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
      \   'fugitive': '%{exists("*fugitive#head")?fugitive#head():""}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*fugitive#head") && ""!=fugitive#head())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': '|' }
\ }

" TODO:
"   - Statusbar plugin
"   - Markdown plugin
"   - Go plugin
"   - linting?
"   - Tags
"   - Search plugin (fzf)...cope?
"   - bufexplorer?
"   - comments (nerd/commentary)
"   - surround
"   - autopairs
"   - yankstack
"   - multiple-cursors
"   - gundo
"   - goyo/zenroom

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

" }}}
" This line closes all folds in this file on start.
" Preceding space is important, removing will make it not work.
" vim:foldmethod=marker:foldlevel=0
