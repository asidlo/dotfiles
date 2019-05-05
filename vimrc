"==============================================================================
" Author:  Andrew Sidlo
" Updated: April 14, 2019
"==============================================================================
" Section: Leader {{{
"==============================================================================
let mapleader=","

"}}}
"==============================================================================
" Section: Vimrc {{{
"==============================================================================
"Reload vimrc
nnoremap confr :source $MYVIMRC<cr>

"Edit vimrc
nnoremap confe :e ~/.vimrc<cr>

"}}}
"==============================================================================
" Section: Escape {{{
"==============================================================================
"Map jj to exit edit mode while in edit mode
inoremap jj <Esc>

"<Ctrl+c> also exits insert mode

"}}}
"==============================================================================
" Section: Terminal {{{
"==============================================================================
"Open terminal on the bottom
"nnoremap <leader>t :wincmd b \| bel terminal<cr>
"nnoremap <leader>t :term<cr>

"}}}
"==============================================================================
" Section: UI {{{
"==============================================================================
" Lines
"==============================================================================
" Add line numbers
set number

"Linenumbers are relative to current line
"set relativenumber 

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
set cmdheight=2

" Hide mode indicator in command bar, since its covered via lightline
set noshowmode

"==============================================================================
" Margins
"==============================================================================
" Add a bit extra margin to the left
set foldcolumn=0

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
"==============================================================================
" Section: Syntax {{{
"==============================================================================
"Use nxlog syntax when opening log files
"au BufRead *.log set filetype=nxlog

"https://github.com/tetsuo13/vim-log4j
"autocmd BufRead,BufNewFile *.log set syntax=log4j
au BufRead,BufNewFile *.log set syntax=log

"}}}
"==============================================================================
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
"nmap < :vertical res +1<Enter>
"nmap < :vertical res +1<Enter>
nmap > <C-w>>
nmap < <C-w><

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

" Quit a buffer
nmap <leader>q :q<cr>

"}}}
"==============================================================================
" Section: Folds {{{
"==============================================================================
" https://vim.fandom.com/wiki/Make_views_automatic
" Save folds in between buffer sessions
au BufWinLeave *.* mkview
au BufWinEnter *.* silent loadview
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
"==============================================================================
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
"==============================================================================
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

" allows incsearch highlighting for range commands
cnoremap $t <CR>:t''<CR>
cnoremap $T <CR>:T''<CR>
cnoremap $m <CR>:m''<CR>
cnoremap $M <CR>:M''<CR>
cnoremap $d <CR>:d<CR>``

"}}}
"==============================================================================
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

" Automatically saves a file when calling :make, such as is done
" in go commands
set autowrite

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
"==============================================================================
" Section: Plugins {{{
"==============================================================================
" Enable Plugins
"==============================================================================
"Enable filetype plugins
filetype plugin on
filetype indent on

"}}}
"==============================================================================
" Section: Text {{{
"==============================================================================
" Text Config
"==============================================================================
" Linebreak on 500 characters if set wrap
set lbr
set tw=500
set nowrap

" How to represent non-printable characters
" In general, don't want tabs, so have them show up as special characters
set listchars=tab:>-,trail:_,extends:>,precedes:<,nbsp:~
set showbreak=\\ "
set list "turn the above on

" Shortcut to rapidly toggle `set list`
nmap <leader>l :set list!<CR>


" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" For regular expressions turn magic on
set magic

" Quickly insert an empty new line without entering insert mode
nnoremap <Leader>o o<Esc>k
nnoremap <Leader>O O<Esc>j
"==============================================================================
" Notes/Tips
"==============================================================================
" Clear till end of line
" c$
" Delete till end of line
" d$

" }}}
"==============================================================================
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
"==============================================================================
" Section: Tabs {{{
"==============================================================================
" Tabs
"==============================================================================
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces (tabstop)
set shiftwidth=4
set tabstop=4

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
"==============================================================================
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
"==============================================================================
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
"==============================================================================
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
"set wildmode=longest:full,full

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" }}}
"==============================================================================
" Section: Autocomplete {{{
"==============================================================================
" Date
"==============================================================================
" Add date -> type XDATE lowercase followed by a char will autofill the date
iab xdate <c-r>=strftime("%d/%m/%y %H:%M:%S")<cr>

" }}}
"==============================================================================
" Section: Plugins {{{
"==============================================================================
" Comfortable-Motion {{{
"==============================================================================
let g:comfortable_motion_no_default_key_mappings = 1

" I want to keep the default mappings for d/u, but not for f/b
nnoremap <silent> <C-d> :call comfortable_motion#flick(100)<CR>
nnoremap <silent> <C-u> :call comfortable_motion#flick(-100)<CR>

" }}}
"==============================================================================
" NerdTree {{{
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

" Close automatically if nerd tree is only buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

map <leader>nn :NERDTreeToggle %<cr>
map <leader>nb :NERDTreeFromBookmark<Space>
map <leader>nf :NERDTreeFind<cr>
nmap <leader>n? :map <leader>n<cr>

" }}}
"==============================================================================
" Fugitive {{{
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

" }}}
"==============================================================================
" Tabularize {{{
"==============================================================================
" NOTE:
"   - f = format
"   - t = table
if exists(":Tabularize")
  nmap <leader>f= :Tabularize /=<CR>
  vmap <leader>f= :Tabularize /=<CR>
  nmap <leader>f: :Tabularize /:\zs<CR>
  vmap <leader>f: :Tabularize /:\zs<CR>
  nmap <leader>ft :Tabularize /\|<CR>
  vmap <leader>ft :Tabularize /\|<CR>
  nmap <leader>f? :map <leader>f<cr>
endif

" }}}
"==============================================================================
" Lightline {{{
"==============================================================================
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ 'active': {
      \   'left': [ ['mode'],
      \             [ 'filename','fugitive' ]],
      \ 'right': [[ 'lineinfo' ], ['percent'], ['fileformat', 'fileencoding', 'filetype' ]]
      \ },
      \ 'inactive': {
      \   'left': [['filename']],
      \   'right': [[ 'lineinfo' ], ['percent']]
      \ },
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \   'fileformat': 'LightlineFileformat',
      \   'filetype': 'LightlineFiletype',
      \   'fileencoding': 'LightlineFileencoding',
      \   'mode': 'LightlineMode',
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help" ? "" : &modified ? "+" : &modifiable ? "" : "-"}',
      \   'fugitive': '%{exists("*fugitive#head") ? winwidth(0) > 70 ? fugitive#head(): "" : "" }'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(winwidth(0) > 70 && &filetype!="help"&& &readonly)',
      \   'modified': '(winwidth(0) > 70 && &filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(winwidth(0) > 70 && exists("*fugitive#head") && ""!=fugitive#head())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': '|', 'right': '|' }
\ }

" }}}
"==============================================================================
" Tagbar {{{
"==============================================================================
map <leader>tb :TagbarToggle<cr>

" }}}
"==============================================================================
" Vim-EasyMotion {{{
"==============================================================================
" Disable default mappings
let g:EasyMotion_do_mapping = 0 

" Turn on case-insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)


" }}} 
"==============================================================================
" Vim-Go {{{
"==============================================================================
" For walkthrough, use the following github repo as example:
" - https://github.com/fatih/vim-go-tutorial#quick-setup
"
" Makes all popup buffers quickfix type buffers
let g:go_list_type = "quickfix"

" Automatically format and also rewrite your import declarations
" If it is too slow, you can use the manual :GoImports command
let g:go_fmt_command = "goimports"

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1

" Run current file
map <leader>gr :GoRun %<cr>
map <leader>gb :GoBuild<cr>
autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
autocmd FileType go nmap <leader>r  <Plug>(go-run)

" Go to next/previous (quickfix) error
map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>

" Close quickfix(error) buffer
autocmd FileType go nmap <leader>a :cclose<CR>

" Run all tests
map <leader>gt :GoTest<cr>

" Run test for func
map <leader>gtf :GoTestFunc<cr>
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <leader>tf  <Plug>(go-test-func)

" Code coverage
autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)

" Dont show nonvisible chars with go files since gofmt removes eol spaces
autocmd Filetype go set nolist

" View the go def stack
" Clear by calling :GoDefStackClear
nmap <leader>gds :GoDefStack<cr>

" Run linting on save
let g:go_metalinter_autosave = 1

" Toggle between test and source code files
nmap <leader>ga :GoAlternate<cr>

" Add new commands for opening alternate files via splits or tabs
autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')

nmap <leader>gas :AS<cr>
nmap <leader>gav :AV<cr>
nmap <leader>gat :AT<cr>

" If you don't know what your next destination is?
" Or you just partially know the name of a function?
" Think (methods)
autocmd Filetype go nmap <leader>m :GoDecls<cr>

" Think (more methods)
autocmd Filetype go nmap <leader>mm :GoDeclsDir

" Show documentation
" Think (method docs)
autocmd Filetype go nmap <leader>d :GoDoc<cr>

" Show method info/params
autocmd FileType go nmap <Leader>i <Plug>(go-info)

" Automatically show when cursor on method
let g:go_auto_type_info = 1

" Make show time faster than default 800 ms
set updatetime=300

"==============================================================================
" Tips/Tricks
"==============================================================================
" | command     | description                                      |
" | vaf         | select whole function (including comments)       |
" | vif         | select function body only                        |
" | dif         | delete function body                             |
" | yif         | copy function body                               |
" | <C-]> or gd | go to declaration                                |
" | <C-t>       | go back a definition                             |
" | ]]          | jump to next function (accepts v]], y]], d]]...) |
" | [[          | jump to previous function                        |

" }}} 
"==============================================================================
" UltiSnips {{{
"==============================================================================
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" Go Snippets List
" - https://github.com/fatih/vim-go/blob/master/gosnippets/UltiSnips/go.snippets
"
" | Shortcut | Snippet                        |
" | -------- | -------------------------------|
" | fn       | fmt.Println()                  |
" | ff       | fmt.Printf()                   |
" | ln       | log.Println()                  |
" | lf       | log.Printf()                   |
" | errp     | if != nil...panic()            |
" | json     | adds json serializer to struct |

" }}}
"==============================================================================
" Ctrlp {{{
"==============================================================================
" Assign <C-f> to start Ctrlp, opens mru by default
let g:ctrlp_map = '<c-f>'

" View open buffers
noremap <c-b> :CtrlPBuffer<cr>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = 'node_modules\|^\.DS_Store\|^\.git'

" | Mapping                        | Description                                                                                                    |
" | <F5>                           | purge the cache for the current directory to get new files, remove deleted files and apply new ignore options.
" | <c-f> / <c-b>                  | to cycle between modes.
" | <c-d>                          | to switch to filename only search instead of full path.
" | <c-r>                          | to switch to regexp mode.
" | <c-j>, <c-k> or the arrow keys | to navigate the result list.
" | <c-t> or <c-v>, <c-x>          | to open the selected entry in a new tab or in a new split.
" | <c-n>, <c-p>                   | to select the next/previous string in the prompt's history.
" | <c-y>                          | to create a new file and its parent directories.
" | <c-z>                          | to mark/unmark multiple files and <c-o> to open them.


" }}}
"==============================================================================
" }}}
"==============================================================================
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

function! LightlineFilename()
  let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  let modified = &modified ? ' +' : ''
  let ro = &readonly ? ' 🔒' : ''

  if filename =~# '__Tagbar__'
    return 'Tagbar' . ro
  endif

  if filename =~# 'NERD_tree'
    return 'NerdTree' . ro
  endif

  if &readonly
    return filename . ro
  else
    return filename . modified
  endif

endfunction

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFileencoding()
  return winwidth(0) > 70 ? (&fileencoding !=# '' ? &fileencoding : ''): ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : '') : ''
endfunction

"\ @% =~# 'NERD_tree' ? 'NerdTree' :
function! LightlineMode()
  return winwidth(0) > 70 ? &paste ? lightline#mode() . ' (PASTE)' : lightline#mode() : ''
endfunction

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

" }}}
"==============================================================================

" This line closes all folds in this file on start.
" Preceding space is important, removing will make it not work.
" vim:foldmethod=marker