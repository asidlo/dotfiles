"==============================================================================
" Author: Andrew Sidlo
" Description: Vim/Nvim configuration file
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
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

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

  " Follow symlinks
  Plug 'moll/vim-bbye'
  Plug 'aymericbeaumet/vim-symlink'

  Plug 'vim-scripts/ReplaceWithRegister'
  Plug 'kana/vim-textobj-user'
  Plug 'kana/vim-textobj-function'

  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'Shougo/echodoc.vim'

  Plug 'scrooloose/nerdtree'
  Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'ryanoasis/vim-devicons'

  Plug 'majutsushi/tagbar'
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'wincent/ferret'

  if g:is_mac
    Plug '/usr/local/opt/fzf'
  else
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  endif
  Plug 'junegunn/fzf.vim'
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

set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store

"}}}
" Plugin: FZF {{{
"==============================================================================
let g:fzf_action = {
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }

nnoremap <Leader>N :Files<cR>
nnoremap <Leader>n :GFiles<cr>
nnoremap <Leader>b :Buffers<cr>
nnoremap <Leader>E :History<cr>
nnoremap <Leader>x :Maps<cr>
nnoremap <Leader>X :Commands<cr>

" Dracula adds the CursorLine highlight to fzf
let g:fzf_colors =
  \ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Disable preview with windows since fzf.vim internally uses a bash script to
" render preview window even though I can do the same with cmd using bat
if g:is_win
  let g:fzf_preview_window = ''
endif

" }}}
" Plugin: FERRET {{{
"==============================================================================
" If you want to do a global replace, you need to search for the term to add it
" to the ferret quickfix, then all instances in the quickfix will be subject to
" the replacement matching when using FerretAcks
let g:FerretMap = 0

" having issues with ferret hanging on windows with nvim using async and job cancel
" this will disable the async feature to make searches sync on win nvim
" see: https://github.com/wincent/ferret/issues/60
if g:is_win && g:is_nvim
  let g:FerretNvim = 0
  let g:FerretJob = 0
endif

" Searches whole project, even through ignored files
nnoremap \ :Ack<space>

" Search for current word
nmap <F7> <Plug>(FerretAckWord)

" Need to use <C-U> to escape visual mode and not enter search
vmap <F7> :<C-U>call <SID>ferret_vack()<CR>

function! s:ferret_vack() abort
  let l:selection = s:get_visual_selection()
  for l:char in [' ', '(', ')']
      let l:selection = escape(l:selection, l:char)
  endfor
  execute ':Ack ' . l:selection
endfunction

" https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
function! s:get_visual_selection()
  " Why is this not a built-in Vim script function?!
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0
      return ''
  endif
  let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction

" Replace instances matching term in quickfix 'F19 == S-F7'
nmap <F19> <Plug>(FerretAcks)

" }}}
" Plugin: GUTENTAGS {{{
"==============================================================================
if g:is_mac
  let g:ctags_exe = '/usr/local/opt/universal-ctags/bin/ctags'
else
  let g:ctags_exe = 'ctags'
endif

let g:gutentags_ctags_executable=g:ctags_exe
let g:gutentags_ctags_exclude=['.git', 'node_modules', '.idea']

"}}}
" Plugin: TAGBAR {{{
"==============================================================================
nnoremap yot :TagbarToggle<cr>
nnoremap [ot :TagbarOpen<cr>
nnoremap ]ot :TagbarClose<cr>

" }}}
" Plugin: AIRLINE {{{
"==============================================================================
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tagbar#enabled = 0
let g:airline#extensions#tabline#fnamemod = ':t'

let g:airline_theme='dracula'
let g:airline_powerline_fonts = 1
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.whitespace=''
let g:airline_symbols.linenr = ''
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.notexists = ' ??'
let g:airline_symbols.readonly = ''
let g:airline_symbols.dirty=' M'

"Reduces the space occupied by section z
let g:airline_section_z = "%3p%% %l:%c"

"}}}
" Plugin: NERDTREE {{{
"==============================================================================
let g:NERDTreeWinPos = "left"
let g:NERDTreeWinSize=35

" Prevent fluff from appearing in the file drawer
let NERDTreeIgnore=[
  \ '__pycache__', '^node_modules$', '\~$', '^\.git$', '^\.DS_Store$', '^\.vim$',
  \ '^\.meta$', '^\.settings$', '^\.classpath$', '^\.project$',
  \ '^\.gradle$', '^\.idea$', '^\.metadata$', '^/bin$', '^GPATH$', '^G.*TAGS$', '^tags$'
  \]

" Show hidden files in NERDTree
let NERDTreeShowHidden=1

" Ignore the help-instructions at the top of NERDTree
let NERDTreeMinimalUI=1

" Delete the NERDTree buffer when it's the only one left
let NERDTreeAutoDeleteBuffer=1

nnoremap [oe :NERDTree<cr>
nnoremap ]oe :NERDTreeClose<cr>

" }}}
" Plugin: VIM-DEVICONS {{{
"==============================================================================
"https://github.com/ryanoasis/vim-devicons/wiki/FAQ-&-Troubleshooting#how-do-i-solve-issues-after-re-sourcing-my-vimrc
if exists("g:loaded_webdevicons")
  call webdevicons#refresh()
endif

" }}}
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
" Plugin: COC-NVIM {{{
"==============================================================================
let g:coc_global_extensions = [ 'coc-json', 'coc-python', 'coc-vimlsp', 'coc-java', 'coc-snippets', 'coc-rls']
highlight link CocHighlightText CocUnderline

augroup coc_settings
  autocmd!
  " Highlight the symbol and its references when holding the cursor.
  autocmd CursorHold * silent call CocActionAsync('highlight')

  autocmd FileType java,go,c setlocal formatexpr=CocAction('formatSelected')
  autocmd FileType rust,go,c setlocal formatexpr=CocAction('format')

  " <S-F6> == <F18>
  autocmd FileType java,rust,vim,go,c nmap <buffer> <F18> <Plug>(coc-rename)
  autocmd FileType java,rust,vim,go,c nmap <buffer><silent> <F6> <Plug>(coc-references)

  inoremap <silent><expr> <c-space> coc#refresh()
  imap <C-j> <Plug>(coc-snippets-expand-jump)

  " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
  nmap <silent> [d <Plug>(coc-diagnostic-prev)
  nmap <silent> ]d <Plug>(coc-diagnostic-next)

  autocmd FileType java,rust,vim,go,c nmap <buffer><silent> <C-]> <Plug>(coc-definition)
  autocmd FileType rust,c nmap <buffer><silent> gd <Plug>(coc-declaration)
  autocmd FileType java,rust,go,c nmap <buffer><silent> gD <Plug>(coc-implementation)
  autocmd FileType rust,go,c nmap <buffer><silent> 1gD <Plug>(coc-type-definition)
  autocmd FileType java,rust,vim,go,c nnoremap <buffer><silent><nowait> g0 :<C-u>CocList outline<CR>
  autocmd FileType java,rust,go,c nnoremap <buffer><silent> K :call CocAction('doHover')<CR>

  " enter to select completion
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

  " use tab for easy completion navigation
  inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
augroup end

command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OrganizeImports :call CocAction('runCommand', 'editor.action.organizeImport')
command! -nargs=0 CocStatus echo coc#status()

abbreviate CC CocConfig
abbreviate CLC CocLocalConfig
abbreviate CI CocInfo
abbreviate CD CocDiagnostics
abbreviate CF CocFix
abbreviate CL CocList
abbreviate CX CocCommand
abbreviate CA CocAction
abbreviate CS CocStatus

" }}}
" Plugin: ECHODOC {{{
"==============================================================================
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'signature'

" }}}
" Settings: NX {{{
"==============================================================================
augroup nx_logs
  autocmd!
  autocmd BufEnter agent-service*.log,base-service*.log,gateway-service*.log,compute-service*.log,control-service*.log setlocal syntax=nxlog
augroup END

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
  autocmd BufEnter *.jsh setlocal filetype=java
  autocmd FileType java,groovy setlocal tabstop=4 shiftwidth=4 expandtab colorcolumn=120
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
