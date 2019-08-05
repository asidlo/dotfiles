"==============================================================================
" Author:   Andrew Sidlo
" Updated:  April 14, 2019
"==============================================================================
" Section: Plugin Manager {{{
"==============================================================================

" Automatically download the plug.vim plugin manager vimscript
" Run :PlugInstall to install all plugins
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


call plug#begin('~/.vim/bundle')

Plug 'nanotech/jellybeans.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'
Plug 'itchyny/lightline.vim'
Plug 'plasticboy/vim-markdown'
Plug 'majutsushi/tagbar'
Plug 'mileszs/ack.vim'
Plug 'airblade/vim-rooter'
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'ervandew/supertab'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'AndrewRadev/splitjoin.vim'
Plug 'rhysd/vim-clang-format'
Plug 'tmhedberg/SimpylFold'
Plug 'vim-scripts/indentpython.vim'
" Plug 'ashisha/image.vim'

if has('win32') || has('win32unix')
  let g:__using_fzf = 0
  Plug 'kien/ctrlp.vim'
else
  let g:__using_fzf = 1
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf.vim'
endif

call plug#end()

" }}}
"==============================================================================
" Section: Settings {{{
"==============================================================================
let mapleader=","

syntax enable

try
  colorscheme jellybeans
catch
  colorscheme desert
endtry

" Remap all letters to not execute escape when using alt + letter 
" https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim
if has('win32unix')
  let c='a'
  while c <= 'z'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
  endw
  set ttimeout ttimeoutlen=50
endif

set t_Co=256
set background=dark

if has("gui_running")
  " No toolbars, menu or scrollbars in the GUI
  " set guifont=Hack:h14
  set clipboard+=unnamed
  set guioptions-=m  "no menu
  set guioptions-=T  "no toolbar
  set guioptions-=l
  set guioptions-=L
  set guioptions-=r  "no scrollbar
  set guioptions-=R
endif

" See vulnerability:
" https://github.com/numirias/security/blob/master/doc/2019-06-04_ace-vim-neovim.md
set modelines=0
set nomodeline

" You can bind contents of the visual selection to system primary buffer
" (* register in vim, usually referred as «mouse» buffer) by using
if has('nvim')
  vnoremap <LeftRelease> "*ygv
  set clipboard=unnamed
elseif has('macunix')
  set clipboard^=autoselect
elseif has('win32') || has('win32unix')
  set clipboard=unnamed
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

set cursorline

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=100

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

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
set shiftwidth=2
set tabstop=2

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
if has('win32')
  set shell=powershell
elseif has('win32unix')
  if executable('fish')
    set shell=fish
  else
    set shell=bash
  endif
else
  set shell=fish
endif

if has('nvim')
  " Leader q to exit terminal mode
  tnoremap <Leader>q <C-\><C-n>:bd!<cr>

  " mappings to move out from terminal to other views
  tnoremap <C-h> <C-\><C-n><C-w>h
  tnoremap <C-j> <C-\><C-n><C-w>j
  tnoremap <C-k> <C-\><C-n><C-w>k
  tnoremap <C-l> <C-\><C-n><C-w>l

  tnoremap <C-b> <C-\><C-n>:Buffers<CR>
  tnoremap <C-e> <C-\><C-n>:e#<CR>

  " Note: <c-backspace> should be used for backspace, since normal bs exits insert mode
  " Also, Alt + - should be used instead of just -
  if has('win32')
    " Open terminal in vertical, horizontal and new tab
    nnoremap <leader>tv :vsplit term://powershell -nologo<CR>
    nnoremap <leader>ts :split term://powershell -nologo<CR>
    nnoremap <leader>tt :e term://powershell -nologo<CR>
  else
    " Open terminal in vertical, horizontal and new tab
    if executable('fish')
      nnoremap <leader>tv :vsplit term://fish<CR>
      nnoremap <leader>ts :split term://fish<CR>
      nnoremap <leader>tt :e term://fish<CR>
    else
      nnoremap <leader>tv :vsplit term://bash<CR>
      nnoremap <leader>ts :split term://bash<CR>
      nnoremap <leader>tt :e term://bash<CR>
    endif
  endif

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
if has('nvim')
  if has('win32') || has('win32unix')
    nnoremap confe :e ~\_vimrc<cr>
  else
    if empty(glob('~/.vimrc'))
      nnoremap confe :e $MYVIMRC<cr>
    else
      nnoremap confe :e ~/.vimrc<cr>
    endif
  endif
else
  nnoremap confe :e $MYVIMRC<cr>
endif

" Map jj to exit edit mode while in edit mode
" <Ctrl+c> or <C-[> also exits insert mode
inoremap jj <Esc>

" Switch to last buffer
nnoremap <C-e> :e#<CR>

" save using <C-s> in every mode
" when in operator-pending or insert, takes you to normal mode
nnoremap <C-s> :write<Cr>
vnoremap <C-s> <C-c>:write<Cr>
inoremap <C-s> <Esc>:write<Cr>
onoremap <C-s> <Esc>:write<Cr>

" use `u` to undo, use `U` to redo, mind = blown
nnoremap U <C-r>

"Close all the buffers
nnoremap <C-Q> :bufdo bd<cr>

"https://vim.fandom.com/wiki/Fast_window_resizing_with_plus/minus_keys
"+ increases vertical buffer, - decreases
if bufwinnr(1)
  nnoremap + <C-W>+
  nnoremap - <C-W>-
endif

nnoremap > <C-w>>
nnoremap < <C-w><

" Switch CWD to the directory of the open buffer
nnoremap <leader>cd :cd %:p:h<cr>:pwd<cr>

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"Go back to visual mode after indenting
vnoremap < <gv
vnoremap > >gv

" Use alt+j/k to move line down/up
" https://vim.fandom.com/wiki/Moving_lines_up_or_down
" https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
" Move a line of text using ALT+[jk] or Command+[jk] on mac
if has("macunix")
  nnoremap ∆ mz:m+<cr>`z
  nnoremap ˚ mz:m-2<cr>`z
  vnoremap ∆ :m'>+<cr>`<my`>mzgv`yo`z
  vnoremap ˚ :m'<-2<cr>`>my`<mzgv`yo`z
else
  nnoremap <A-j> :m .+1<CR>==
  nnoremap <A-k> :m .-2<CR>==
  inoremap <A-j> <Esc>:m .+1<CR>==gi
  inoremap <A-k> <Esc>:m .-2<CR>==gi
  vnoremap <A-j> :m '>+1<CR>gv=gv
  vnoremap <A-k> :m '<-2<CR>gv=gv
endif

"Smart way to move between windows
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" Move to the first/last non-blank character on this line
nnoremap H ^
nnoremap L $

" Quick Saving
nmap <leader>w :w<cr>

" Quick quit
nmap <leader>q :q<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
if !exists(':W')
  if !has('win32unix') && !has('win32')
    command W w !sudo tee % > /dev/null
  endif
endif

" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

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

" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
map <space> /

" Bash like keys for the command line
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

" Add date -> type XDATE lowercase followed by a char will autofill the date
iab xdate <c-r>=strftime("%Y/%m/%d %H:%M:%S")<cr>

nnoremap [oq :copen<CR>
nnoremap ]oq :cclose<CR>
nnoremap yoq :call ToggleQuickfix()<CR>

function! s:ToggleQuickfix()
  for winnr in range(1, winnr('$'))
    if getwinvar(winnr, '&syntax') == 'qf'
      cclose
      return
    endif
  endfor
  copen
endfunction

" }}}
"==============================================================================
" Section: Plugins {{{
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

" Auto close nerdtree after opening a buffer
let NERDTreeQuitOnOpen=1

" Close automatically if nerd tree is only buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

nnoremap yoe :NERDTreeToggle<cr>
nnoremap [oe :NERDTree<cr>
nnoremap ]oe :NERDTreeClose<cr>

" }}}
"==============================================================================
" GitGutter {{{
"==============================================================================
let g:gitgutter_map_keys = 0

nnoremap ]h :GitGutterNextHunk<cr>
nnoremap [h :GitGutterPrevHunk<cr>

" }}}
"==============================================================================
" TagBar {{{
"==============================================================================
nnoremap yot :TagbarToggle<cr>
nnoremap [ot :TagbarOpen<cr>
nnoremap ]ot :TagbarClose<cr>

" }}}
"==============================================================================
" Tabularize {{{
"==============================================================================
" NOTE:
"   - t = Tabularize
"   - f = format
"   - p = pipes
nnoremap tf= :Tabularize /=<CR>
vnoremap tf= :Tabularize /=<CR>
nnoremap tfp :Tabularize /\|<CR>
vnoremap tfp :Tabularize /\|<CR>

"}}}
"==============================================================================
" Lightline {{{
"==============================================================================
function! LightlineFilename()
  let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  let modified = &modified ? ' +' : ''

  if has('unix') && !has('win32unix')
    let ro = &readonly ? ' 🔒' : ''
  else
    let ro = &readonly ? ' [ro]' : ''
  endif

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
      \             [ 'filename','fugitive'],
      \             ['cocstatus']
      \    ],
      \ 'right': [
      \           [ 'lineinfo' ], ['percent'],
      \           ['fileformat', 'fileencoding', 'filetype' ],
      \  ]
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
      \   'cocstatus': 'coc#status',
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
" Vim-Go {{{
"==============================================================================
" For walkthrough, use the following github repo as example:
" - https://github.com/fatih/vim-go-tutorial#quick-setup
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

" Disable go def mapping so we can delegate it to the coc lsp
let g:go_def_mapping_enabled=0

" Run linting on save
let g:go_metalinter_autosave = 1

" Automatically highlight matching identifiers (methods, variables...)
let g:go_auto_sameids = 1

" Automatically show info when cursor on method
" Has an issue when putting cursor over lib imports
let g:go_auto_type_info = 1

" Makes all popup buffers quickfix type buffers
" let g:go_list_type = "quickfix"

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

" }}}
"==============================================================================
" FZF {{{
"==============================================================================
if __using_fzf
" if exists('g:loaded_fzf')
  nnoremap <C-F> :Files<CR>
  nnoremap <C-G> :GFiles<CR>
  nnoremap <C-B> :Buffers<CR>
  nnoremap <C-Y> :History<CR>
  nnoremap <C-X> :Maps<CR>


  let g:fzf_colors =
        \ { 'fg':      ['fg', 'Normal'],
        \ 'bg':      ['bg', 'Normal'],
        \ 'hl':      ['fg', 'Comment'],
        \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
        \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
        \ 'hl+':     ['fg', 'Statement'],
        \ 'info':    ['fg', 'PreProc'],
        \ 'border':  ['fg', 'Ignore'],
        \ 'prompt':  ['fg', 'Conditional'],
        \ 'pointer': ['fg', 'Exception'],
        \ 'marker':  ['fg', 'Keyword'],
        \ 'spinner': ['fg', 'Label'],
        \ 'header':  ['fg', 'Comment'] }

endif
" }}}
"==============================================================================
" Ack {{{
"==============================================================================
" Prefer rg > ag > ack
if executable('rg')
  set grepprg=rg\ --vimgrep
  let g:ackprg = 'rg -S --no-heading --no-ignore-vcs --hidden --vimgrep'
elseif executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ackprg = 'ag --vimgrep'
endif

nnoremap \ :Ack<space>
" }}}
"==============================================================================
" Ctrlp {{{
"==============================================================================
if !__using_fzf

  " Assign <C-f> to start Ctrlp, opens mru by default
  let g:ctrlp_map = '<C-F>'

  nnoremap <C-Y> :CtrlPMRUFiles<CR>

  " View open buffers
  nnoremap <C-B> :CtrlPBuffer<CR>

  let g:ctrlp_max_height = 20
  let g:ctrlp_match_window = 'results:100'
  let g:ctrlp_custom_ignore = {
        \ 'dir':  '\v[\/](node_modules|venv)|\.(git|hg|svn)$',
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

  if executable('rg')
    " Ignores files not included in version control since ctrl fuzzy search has
    " issues using rg and doing incremental searches in that way, better to just
    " use ack with rg and type regex and then perform search.
    " For example: (find all log files)
    " :Ack --files -g "*.log"
    let g:ctrlp_user_command = 'rg %s --files --hidden --glob ""'
    let g:ctrlp_use_caching = 0
  elseif executable('ag')
    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
    let g:ctrlp_use_caching = 0
  else
    let g:ctrlp_clear_cache_on_exit = 0
  endif
endif

" }}}
"==============================================================================
" Markdown {{{
"==============================================================================
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_math = 1
let g:vim_markdown_strikethrough = 1

let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
" let g:vim_markdown_no_default_key_mappings = 1

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
" SimpylFold {{{
"==============================================================================
let g:SimpylFold_docstring_preview = 1

" }}}
"==============================================================================
" Clang-Format {{{
"==============================================================================
autocmd FileType c ClangFormatAutoEnable
" set path+=/usr/include

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
" Vim-devicons {{{
"==============================================================================
"https://github.com/ryanoasis/vim-devicons/wiki/FAQ-&-Troubleshooting#how-do-i-solve-issues-after-re-sourcing-my-vimrc
if exists("g:loaded_webdevicons")
  call webdevicons#refresh()
endif

" NERDTrees File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
 exec 'autocmd FileType nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
 exec 'autocmd FileType nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

call NERDTreeHighlightFile('ini', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF', '#151515')
call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('yaml', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('styl', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('php', 'Magenta', 'none', '#ff00ff', '#151515')
call NERDTreeHighlightFile('ds_store', 'Gray', 'none', '#686868', '#151515')
call NERDTreeHighlightFile('gitconfig', 'Gray', 'none', '#686868', '#151515')
call NERDTreeHighlightFile('gitignore', 'Gray', 'none', '#686868', '#151515')
call NERDTreeHighlightFile('bashrc', 'Gray', 'none', '#686868', '#151515')
call NERDTreeHighlightFile('bashprofile', 'Gray', 'none', '#686868', '#151515')
call NERDTreeHighlightFile('bat', 'green', 'none', 'green', '#151515')
call NERDTreeHighlightFile('Vagrantfile', 'cyan', 'none', 'cyan', '#151515')

" }}}
"==============================================================================
" Section: Coc Mappings {{{
"==============================================================================
let g:coc_global_extensions=[
      \ 'coc-json', 'coc-prettier', 'coc-eslint', 'coc-tsserver',
      \ 'coc-html', 'coc-css', 'coc-vetur', 'coc-rls',
      \ 'coc-yaml', 'coc-python', 'coc-lists', 'coc-git',
      \ 'coc-powershell', 'coc-omnisharp', 'coc-marketplace',
      \ 'coc-vimlsp', 'coc-xml', 'coc-ultisnips', 'coc-ccls',
      \ 'coc-java'
      \]
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-@> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

if exists('*CocActionAsync')
  " Highlight symbol under cursor on CursorHold
  autocmd CursorHold * silent call CocActionAsync('highlight')
endif

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
command! -nargs=? Fold :call CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Remap for rename current word
nmap <F6> <Plug>(coc-rename)

" Using CocList
" Show all diagnostics
nnoremap <silent> <leader>z  :<C-u>CocList diagnostics<cr>
" Show all actions
nnoremap <silent> <leader>a  :<C-u>CocList actions<cr>
" Manage extensions
nnoremap <silent> <leader>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <leader>x  :<C-u>CocList commands<cr>
" Find symbol of current document
nmap <silent> <leader>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <leader>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <leader>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <leader>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <leader>p  :<C-u>CocListResume<CR>

" }}}
"==============================================================================
" }}}
"==============================================================================
" Section: Language Specific Mappings {{{
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
  autocmd BufNewFile,BufRead,BufEnter *.go setlocal noexpandtab tabstop=4 shiftwidth=4

  " :GoBuild and :GoTestCompile
  autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>

  " :GoTest
  autocmd FileType go nmap <leader>tt  <Plug>(go-test)
  autocmd FileType go nmap <leader>tf  <Plug>(go-test-func)

  " :GoRun
  autocmd FileType go nmap <leader>r  <Plug>(go-run)

  " :GoCoverageToggle
  " autocmd FileType go nmap <leader>c <Plug>(go-coverage-toggle)

  " :GoDescribe - Show methods for a given class / interface
  autocmd FileType go nmap <C-K> <Plug>(go-describe)

  " :GoMetaLinter
  autocmd FileType go nmap <leader>l <Plug>(go-metalinter)

  " :GoDef but opens in a vertical split
  autocmd FileType go nmap <leader>dv <Plug>(go-def-vertical)

  " :GoDef but opens in a horizontal split
  autocmd FileType go nmap <leader>ds <Plug>(go-def-split)

  " :GoDecls - Show all methods in current file (Methods)
  autocmd Filetype go nmap <leader>o :GoDecls<cr>

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

  " Run :GoBuild or :GoTestCompile based on the go file
  function! s:build_go_files()
    let l:file = expand('%')
    if l:file =~# '^\f\+_test\.go$'
      call go#test#Test(0, 1)
    elseif l:file =~# '^\f\+\.go$'
      call go#cmd#Build(0)
    endif
  endfunction

augroup END

augroup c
  autocmd!
  autocmd FileType c nmap <leader>r :call RunCExe()<CR>
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
augroup END

autocmd FileType json syntax match Comment +\/\/.\+$+
autocmd FileType vim set foldmethod=marker 
autocmd BufNewFile,BufRead CHANGELOG.txt,README.txt set filetype=markdown
autocmd BufRead,BufNewFile agent-service.log,base-service.log,gateway-service.log,compute-service.log,control-service.log set syntax=nxlog
autocmd BufEnter *.png,*.jpg,*.gif,*.jpeg exec "!open ".expand("%:p") | :bw!

au BufNewFile,BufRead *.py
    \ set tabstop=4
    \ set softtabstop=4
    \ set shiftwidth=4
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix

" }}}
"==============================================================================
" Section: Functions {{{
"=============================================================================
command! -complete=file -nargs=* ShellGitCmd call s:RunGitShellCommand('git '.<q-args>)
command! -complete=shellcmd -nargs=+ ShellCmd call s:RunShellCommand(<q-args>)
command! -complete=file -nargs=* Gradle call s:RunShellCommand('gradle '.<q-args>)

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

" }}}
"==============================================================================
