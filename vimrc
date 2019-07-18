"==============================================================================
" Author:   Andrew Sidlo
" Updated:  April 14, 2019
"==============================================================================
" Section: Plugin Manager {{{
"==============================================================================
"
" Automatically download the plug.vim plugin manager vimscript
" Run :PlugInstall to install all plugins
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" coc-yank seems neat, but is causing a bunch of issues writing invalid json to
" its config file
let lang_servers='
            \ coc-json coc-prettier coc-eslint coc-tsserver
            \ coc-html coc-css coc-vetur coc-java coc-rls
            \ coc-yaml coc-python coc-lists coc-git
            \ coc-vimlsp coc-xml
            \'

call plug#begin('~/.vim/bundle')
Plug 'nanotech/jellybeans.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'yuttie/comfortable-motion.vim'
Plug 'godlygeek/tabular'
Plug 'itchyny/lightline.vim'
Plug 'plasticboy/vim-markdown'
Plug 'majutsushi/tagbar'
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-commentary'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'ervandew/supertab'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall '.lang_servers}
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'AndrewRadev/splitjoin.vim'
Plug 'rhysd/vim-clang-format'
call plug#end()

" }}}
"==============================================================================
" Section: Settings {{{
"==============================================================================
let mapleader=","

syntax enable
colorscheme jellybeans
set background=dark

" See vulnerability:
" https://github.com/numirias/security/blob/master/doc/2019-06-04_ace-vim-neovim.md
set modelines=0
set nomodeline

" You can bind contents of the visual selection to system primary buffer
" (* register in vim, usually referred as «mouse» buffer) by using
if has('nvim')
    vnoremap <LeftRelease> "*ygv
else
    set clipboard^=autoselect
endif

" Dont insert first suggestion from autocompletions (omnicomplete)
" https://vim.fandom.com/wiki/Make_Vim_completion_popup_menu_work_just_like_in_an_IDE
set completeopt=longest,menuone

" Enable mouse support for specific modes
set mouse=a

"Enable filetype plugins
filetype plugin on
filetype indent on

" Disable autofolding
set nofoldenable

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

" Height of the command bar
set cmdheight=2

" Hide mode indicator in command bar, since its covered via lightline
set noshowmode

" Add a bit extra margin to the left
set foldcolumn=0

" Don't redraw while executing macros (good performance config)
set lazyredraw

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" Always show the status line
set laststatus=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" A buffer becomes hidden when it is abandoned
set hid

"New splits below, not above
set splitbelow

"New splits on the right, not left
set splitright

" Specify the behavior when switching between buffers
" try
"   set switchbuf=useopen,usetab,newtab
" catch
" endtry

" Make merging lines smarter when using <shift-j>
if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j
endif

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Set to auto read when a file is changed from the outside
set autoread

" Automatically saves a file when calling :make, such as is done
" in go commands
set autowrite

" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

" Linebreak on 500 characters if set wrap
set lbr
set tw=500
set nowrap

" How to represent non-printable characters
" In general, don't want tabs, so have them show up as special characters
set listchars=tab:>-,trail:_,extends:>,precedes:<,nbsp:~
set showbreak=\\ "
set list "turn the above on

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" For regular expressions turn magic on
set magic

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch 

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces (tabstop)
set shiftwidth=4
set tabstop=4

set ai "Auto indent
set si "Smart indent

" Show tab number only if more than 1
set stal=1

" Sets how many lines of history VIM has to remember
set history=500

" Disable the netrw history file which is otherwise added to ~/.vim/.netrwhist
let g:netrw_dirhistmax = 0

" This enables us to undo files even if you exit Vim.
" Note: this dir needs to be made prior to working
set undodir=~/.vim/tmp/undo
set undofile

" Turn on the Wild menu
" https://stackoverflow.com/questions/9511253/how-to-effectively-use-vim-wildmenu
set wildmenu
set wildmode=longest:full,full

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif
"}}}
"==============================================================================
" Section: Mappings {{{
"==============================================================================
" Visual linewise up and down by default (and use gj gk to go quicker)
" Move cusor by display lines when wrapping
noremap <Up> gk
noremap <Down> gj
noremap j gj
noremap k gk

" Terminal settings
if has('nvim')
  " Leader q to exit terminal mode. Somehow it jumps to the end, so jump to
  " the top again
  tnoremap <Leader>q <C-\><C-n>gg<cr>

  " mappings to move out from terminal to other views
  tnoremap <C-h> <C-\><C-n><C-w>h
  tnoremap <C-j> <C-\><C-n><C-w>j
  tnoremap <C-k> <C-\><C-n><C-w>k
  tnoremap <C-l> <C-\><C-n><C-w>l

  tnoremap <C-b> <C-\><C-n>:CtrlPBuffer<CR>
  tnoremap <C-f> <C-\><C-n>:CtrlP<CR>

  if bufwinnr(1)
    tnoremap + <C-W>+
    tnoremap - <C-W>-
  endif
  
  "Alt + Shift + > increases buffer width +1
  "Alt + Shift + < decreases buffer width -1
  "nmap < :vertical res +1<Enter>
  "nmap < :vertical res +1<Enter>
  tnoremap > <C-w>>
  tnoremap < <C-w><

  " Open terminal in vertical, horizontal and new tab
  nnoremap <leader>tv :vsplit term://zsh<CR>
  nnoremap <leader>ts :split term://zsh<CR>
  nnoremap <leader>tt :e term://zsh<CR>

  " always start terminal in insert mode
  autocmd BufWinEnter,WinEnter term://* startinsert
endif

" Enter key will simply select the highlighted menu item, just as <C-Y> does
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

" Act like D and C
" yank from current position till end of line
nnoremap Y y$

" Reload vimrc
nnoremap confr :source $MYVIMRC<cr>

" Edit vimrc
nnoremap confe :e ~/.vimrc<cr>

" Map jj to exit edit mode while in edit mode
" <Ctrl+c> also exits insert mode
inoremap jj <Esc>

"Close the current buffer
map <leader>bd :bd<cr>

"Close all the buffers
map <leader>ba :bufdo bd<cr>

"Closing buffers
"<C-w>c -> closes current buffer

"Open scratch buffer
map <leader>bn :e ~/buffer<cr>
map <leader>bm :e ~/buffer.md<cr>

"https://stackoverflow.com/questions/1269603/to-switch-from-vertical-split-to-horizontal-split-fast-in-vim
"Changed tv and th for **To Vertical** and **To Horizontal**
"Horizontal buffer to vertical
nmap <leader>bv <c-w>t<c-w>H

"Vertical buffer to horizontal
nmap <leader>bs <c-w>t<c-w>K

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

"https://vim.fandom.com/wiki/Buffers
"<C-w>s -> Horizontal split
"<C-w>v -> Vertical split

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>


" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Quit a buffer
nmap <leader>q :q<cr>

" https://vim.fandom.com/wiki/Make_views_automatic
" Save folds in between buffer sessions
" au BufWinLeave *.* mkview
" au BufWinEnter *.* silent loadview
" TODO - Figure out how to make this work when closing all buffers, and opening

"https://vim.fandom.com/wiki/Folding

" | Command | Description      |
" | za      | Toggle fold      |
" | zo      | Open fold        |
" | zc      | Close fold       |
" | zR      | Open all folds   |
" | zM      | Close all folds  |
" | zi      | Toggle all folds |

"Go back to visual mode after indenting
vnoremap < <gv
vnoremap > >gv

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

"Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Move to the first/last non-blank character on this line
map H ^
map L $


" allows incsearch highlighting for range commands
cnoremap $t <CR>:t''<CR>
cnoremap $T <CR>:T''<CR>
cnoremap $m <CR>:m''<CR>
cnoremap $M <CR>:M''<CR>
cnoremap $d <CR>:d<CR>``

" Quick Saving
nmap <leader>w :w<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
" command W w !sudo tee % > /dev/null

"==============================================================================
" Notes/Tips
"==============================================================================
" ZZ saves and quits

" Shortcut to rapidly toggle `set list` for showing misc eol chars, tabs, etc
nmap <leader>l :set list!<CR>

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

" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
map <space> /

" if has('mac') || has('macunix')
"   map <c-@> ?
" else
"   map <c-space> ?
" endif

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Useful mappings for managing tabs
" map <leader>tn :tabnew<cr>
" map <leader>to :tabonly<cr>
" map <leader>tc :tabclose<cr>
" map <leader>tm :tabmove
" map <leader>t<leader> :tabnext

" Let 'tl' toggle between this and the last accessed tab
" let g:lasttab = 1
" nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
" au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
" map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

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

" Bash like keys for the command line
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>

cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

" Add date -> type XDATE lowercase followed by a char will autofill the date
iab xdate <c-r>=strftime("%d/%m/%y %H:%M:%S")<cr>

" Navigate quickfix buffers
nnoremap <leader>cc :cclose<CR>
nnoremap <leader>co :copen<CR>
nnoremap <leader>cn :cnext<CR>
nnoremap <leader>cp :cprevious<CR>

" =============================================================================
" Notes/Tips
" =============================================================================
" | Mapping | Description       |
" | gg=G    | indent whole file |

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

map <leader>nn :NERDTreeToggle<cr>
map <leader>nb :NERDTreeFromBookmark<Space>
map <leader>nf :NERDTreeFind<cr>
nmap <leader>n? :map <leader>n<cr>

" }}}
"==============================================================================
" Fugitive {{{
"==============================================================================
nmap <leader>gb :Gblame<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>gd :Gvdiff<cr>
nmap <leader>gg :Ggrep
nmap <leader>gl :Glog<cr>
nmap <leader>gs :Gstatus<cr>
nmap <leader>gw :Gbrowse<cr>
nmap <leader>g? :map <leader>g<cr>

" Notes/Tips
" - Type 'g?' while in GitStatus to see all command mappings

" https://github.com/tpope/vim-fugitive/issues/582
" - Just use Gvdiff instead
" set diffopt+=vertical
"
" }}}
"==============================================================================
" GitGutter {{{
"==============================================================================
" let g:gitgutter_map_keys= 0
" let g:gitgutter_enabled = 0

nmap ]h <Plug>GitGutterNextHunk
nmap [h <Plug>GitGutterPrevHunk

" }}}
"==============================================================================
" Tabularize {{{
"==============================================================================
" NOTE:
"   - f = format
"   - t = table
nmap <leader>f= :Tabularize /=<CR>
vmap <leader>f= :Tabularize /=<CR>
nmap <leader>f: :Tabularize /:\zs<CR>
vmap <leader>f: :Tabularize /:\zs<CR>
nmap <leader>ft :Tabularize /\|<CR>
vmap <leader>ft :Tabularize /\|<CR>
nmap <leader>f? :map <leader>f<cr>

" }}}
"==============================================================================
" Lightline {{{
"==============================================================================
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
" Vim-Go {{{
"==============================================================================
" For walkthrough, use the following github repo as example:
" - https://github.com/fatih/vim-go-tutorial#quick-setup
"
" Change the underlying go def tool from guru to 'godef'
" let g:go_def_mode = 'godef'
" Note: Go modules are required to be in the project you are working on when using
"       gopls for godef and goinfo commands
"       Also note that while in GOPATH, gopls with start omnifunc after .
"       Whereas outside of GOPATH <C-X><C-O> is required to activate it
"       Another note: if directory is symlinked, where the source is in GOPATH
"       gorename will work as expected
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

" Run linting on save
let g:go_metalinter_autosave = 1

" Make show time faster than default 800 ms
" set updatetime=300

" Automatically highlight matching identifiers (methods, variables...)
let g:go_auto_sameids = 1

" Automatically show info when cursor on method
" let g:go_auto_type_info = 1

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

" }}}
"==============================================================================
" UltiSnips {{{
"==============================================================================
" Better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" If you want :UltiSnipsEdit to split your window.
" let g:UltiSnipsEditSplit="vertical"

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
" YouCompleteMe {{{
"==============================================================================
" make YCM compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
let g:SuperTabDefaultCompletionType = '<C-n>'

let g:ycm_global_ycm_extra_conf = "~/.ycm_extra_conf.py"

" }}}
"==============================================================================
" Ctrlp {{{
"==============================================================================
" Assign <C-f> to start Ctrlp, opens mru by default
let g:ctrlp_map = '<c-f>'

" View open buffers
noremap <c-b> :CtrlPBuffer<cr>

let g:ctrlp_max_height = 20
" let g:ctrlp_custom_ignore = 'node_modules\|^\.DS_Store\|^\.git)'
let g:ctrlp_custom_ignore = {
  \ 'dir':  'node_modules\|\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v\.(exe|so|dll|class|DS_Store|jar)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }

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
" Markdown {{{
"==============================================================================
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_math = 1
let g:vim_markdown_strikethrough = 1

let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0

autocmd FileType markdown nmap tf :TableFormat<cr>
autocmd FileType markdown nmap toc :Toc<cr>


" }}}
"==============================================================================
" Commentary {{{
"==============================================================================
autocmd FileType text setlocal commentstring=#\ %s
autocmd FileType json setlocal commentstring=//\ %s

" }}}
"==============================================================================
" YankStack {{{
"==============================================================================
let g:yankstack_yank_keys = ['y', 'd']

nmap <c-P> <Plug>yankstack_substitute_older_paste
nmap <c-p> <Plug>yankstack_substitute_newer_paste

" }}}
"==============================================================================
" Clang-Format {{{
"==============================================================================
autocmd FileType c ClangFormatAutoEnable
set path+=/usr/include

let g:clang_format#style_options = {
            \ "AccessModifierOffset" : -4,
            \ "AllowShortIfStatementsOnASingleLine" : "true",
            \ "AlwaysBreakTemplateDeclarations" : "true",
            \ "Standard" : "C++11",
            \ "BreakBeforeBraces" : "Stroustrup"}
" }}}
"==============================================================================
" Supertab {{{
"==============================================================================
let g:SuperTabDefaultCompletionType = "<c-n>"

" }}}
"==============================================================================
" Section: Coc Mappings {{{
"==============================================================================
" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Use K to see documentation in a popup preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction


" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Remap for rename current word
nmap <F6> <Plug>(coc-rename)

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-@> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" }}}
"==============================================================================
" }}}
"==============================================================================
" Section: C Mappings {{{
"==============================================================================
" Ideas:
"  - Could add a directory to path and build executable into specified dir
"  - Then could just run executable by name from dir (similar to go)
"
" Need to separate this out into a function for the execution and a cmd group
" for eventual more c mappings
"
autocmd FileType c nmap <leader>r :call RunCExe()<CR>

" }}}
"==============================================================================
" Section: Go Mappings {{{
"==============================================================================

"==============================================================================
" Tips/Tricks
"==============================================================================
" | command         | description                                                                                         |
" | vaf             | select whole function (including comments)                                                          |
" | vif             | select function body only                                                                           |
" | dif             | delete function body                                                                                |
" | yif             | copy function body                                                                                  |
" | <C-]> or gd     | go to declaration                                                                                   |
" | <C-t>           | go back a definition                                                                                |
" | ]]              | jump to next function (accepts v]], y]], d]]...)                                                    |
" | [[              | jump to previous function                                                                           |
" | :GoWhicherrs    | Shows which types of errors can occur from error return type                                        |
" | :GoChannelPeers | Shows information about a selected channel                                                          |
" | :GoCallees      | Shows all possible targets for the current function                                                 |
" | :GoCallers      | Shows which functions call the current function and navigates to the usage, similar to GoReferrers  |
" | :GoRename       | refactor renames current identifier(only works in GOPATH)                                           |
" | :GoFreevars     | shows variables that are referenced but not defined within a given selection, helps for refactoring |
" | :GoGenerate     | runs go generate                                                                                    |
" | :GoImpl         | generates methods for a given interface                                                             |
"
" Can also do GoImpl anywhere in file, just specify which type to attach it to
" :GoImpl b *B fmt.Stringer
" Can be custom impl also: :GoImpl github.com/asidlo/algorithms/collections.Stack

augroup go
    autocmd!

    " Show by default 4 spaces for a tab
    autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4

    " :GoBuild and :GoTestCompile
    autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>

    " :GoTest
    autocmd FileType go nmap <leader>t  <Plug>(go-test)
    autocmd FileType go nmap <leader>tf  <Plug>(go-test-func)

    " :GoRun
    autocmd FileType go nmap <leader>r  <Plug>(go-run)

    " :GoDoc
    autocmd FileType go nmap <Leader>d <Plug>(go-doc)

    " :GoCoverageToggle
    autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)

    " :GoInfo
    autocmd FileType go nmap <Leader>i <Plug>(go-info)

    " :GoDescribe - Show methods for a given class / interface
    autocmd FileType go nmap <Leader>ii <Plug>(go-describe)

    " :GoMetaLinter
    autocmd FileType go nmap <Leader>l <Plug>(go-metalinter)

    " :GoDef but opens in a vertical split
    autocmd FileType go nmap <Leader>v <Plug>(go-def-vertical)

    " :GoDef but opens in a horizontal split
    autocmd FileType go nmap <Leader>s <Plug>(go-def-split)

    " :GoDecls - Show all methods in current file (Methods)
    autocmd Filetype go nmap <leader>m :GoDecls<cr>

    " Open :GoDeclsDir with ctrl-g
    autocmd Filetype go nmap <C-g> :GoDeclsDir<cr>
    autocmd Filetype go imap <C-g> <esc>:<C-u>GoDeclsDir<cr>
    " Intellij mapping
    autocmd Filetype go nmap <F12> :GoDeclsDir<cr>
    autocmd Filetype go imap <F12> <esc>:<C-u>:GoDeclsDir<cr>

    " Show all files in current package
    autocmd Filetype go nmap ls :GoFiles<cr>

    " Show all dependencies of current file
    autocmd Filetype go nmap deps :GoDeps<cr>

    " Find usages
    autocmd Filetype go nmap refs :GoReferrers<cr>

    " Shows all interfaces current type/struct implements
    autocmd Filetype go nmap <C-i> :GoImplements<cr>

    " :GoAlternate  commands :A, :AV, :AS and :AT
    autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
    autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
    autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
    autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')

    " Dont show nonvisible chars with go files since gofmt removes eol spaces
    autocmd Filetype go set nolist
augroup END

" }}}
"==============================================================================
" Section: JSON Mappings {{{
"==============================================================================
autocmd FileType json syntax match Comment +\/\/.\+$+

" }}}
"==============================================================================
" Section: Functions {{{
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

" Run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

command! -complete=file -nargs=* Vig call s:RunGitShellCommand('git '.<q-args>)

function! s:RunGitShellCommand(cmdline)
  let isfirst = 1
  let words = []
  for word in split(a:cmdline)
    if isfirst
      let isfirst = 0  " don't change first word (shell command)
    else
      if word[0] =~ '\v[%#<]'
        let word = expand(word)
      endif
      let word = shellescape(word, 1)
    endif
    call add(words, word)
  endfor
  let expanded_cmdline = join(words)
  botright new
  setlocal buftype=nofile syntax=fugitive bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:  ' . a:cmdline)
  call setline(2, 'Expanded to:  ' . expanded_cmdline)
  call append(line('$'), substitute(getline(2), '.', '=', 'g'))
  silent execute '$read !'. expanded_cmdline
  1
endfunction

command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
command! -complete=file -nargs=* Gradle call s:RunShellCommand('gradle '.<q-args>)
command! -complete=file -nargs=* Ls call s:RunShellCommand('ls '.<q-args>)
command! -complete=file -nargs=* Rm call s:RunShellCommand('rm '.<q-args>)
command! -complete=file -nargs=* Mv call s:RunShellCommand('mv '.<q-args>)

" https://vim.fandom.com/wiki/Display_output_of_shell_commands_in_new_window
function! s:RunShellCommand(cmdline)
  let isfirst = 1
  let words = []
  for word in split(a:cmdline)
    if isfirst
      let isfirst = 0  " don't change first word (shell command)
    else
        let word = substitute(word, '\v[%$<]', expand('%'), '')
    endif
    call add(words, word)
  endfor
  let expanded_cmdline = join(words)
  botright new
  setlocal buftype=nofile syntax=sh bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:  ' . a:cmdline)
  call setline(2, 'Expanded to:  ' . expanded_cmdline)
  call append(line('$'), substitute(getline(2), '.', '=', 'g'))
  silent execute '$read !'. expanded_cmdline
  1
endfunction

" https://vim.fandom.com/wiki/Get_the_name_of_the_current_file
function! BuildCExe()
    execute "!gcc -Wall -o %:p:h/a.out %:p"
endfunction

function! RunCExe()
    silent execute BuildCExe()
    execute "!%:p:h/a.out"
    silent execute RmCExe()
endfunction

function! RmCExe()
    execute "!rm %:p:h/a.out"
endfunction
" }}}
"==============================================================================
" This line closes all folds in this file on start.
" Preceding space is important, removing will make it not work.
" vim:foldmethod=marker
