let g:vim_dir = expand('~/vimfiles')

if empty(glob(g:vim_dir . '/autoload/plug.vim'))
	let g:vim_plug_uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	let g:vim_plug_powershell_download_cmd = 'Invoke-WebRequest -Uri "' . g:vim_plug_uri . '" -OutFile "' . expand(g:vim_dir . '/autoload/plug.vim') . '"'
	silent execute '!powershell -command New-Item -ItemType Directory -Path "' . expand(g:vim_dir . '/autoload') . '"'
	silent execute '!powershell -command ' . g:vim_plug_powershell_download_cmd
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/vimfiles/plugged'))
    Plug 'sheerun/vim-polyglot'
    Plug 'dracula/vim', { 'as': 'dracula' }

    Plug 'OmniSharp/omnisharp-vim'
    Plug 'nickspoons/vim-sharpenup'
    Plug 'dense-analysis/ale'

    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
    Plug 'itchyny/lightline.vim'

    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'

    Plug 'airblade/vim-rooter'
    Plug 'airblade/vim-gitgutter'
    Plug 'rhysd/git-messenger.vim'

    Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

filetype indent plugin on
syntax enable

packadd cfilter
runtime ftplugin/man.vim

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
set completeopt=menuone,noinsert,noselect,popuphidden
set completepopup=highlight:Pmenu,border:off
set clipboard=unnamed
set wildmode=longest:full,full
set wildmenu
set cmdheight=2
set backspace=eol,start,indent

set shortmess+=c
set signcolumn=number

set hlsearch
set incsearch
set showmatch

set wildignore=*.o,*~,*.pyc,*.class
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store

set undofile
set undodir=~/vimfiles/undo

set termguicolors
set t_Co=256

set encoding=utf-8
scriptencoding utf-8

augroup _user_settings
	autocmd!
	autocmd ColorScheme dracula highlight SpellBad gui=undercurl
	autocmd ColorScheme dracula highlight Search ctermbg=NONE guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline
	" Return to last edit position when opening files (You want this!)
	autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
  autocmd ColorScheme * highlight link ALEErrorSign   WarningMsg
  autocmd ColorScheme * highlight link ALEWarningSign ModeMsg
  autocmd ColorScheme * highlight link ALEInfoSign    Identifier
augroup END

try
	let g:dracula_inverse = 0
	let g:dracula_colorterm = 0
	let g:dracula_italic = 0
	let g:dracula_colorterm = 1
	colorscheme dracula
catch
	colorscheme desert
endtry

let mapleader = " "

let g:netrw_dirhistmax = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

let g:python3_host_prog = expand('~\AppData\Local\Microsoft\WindowsApps\python.exe')

if executable('rg')
  set grepformat=%f:%l:%c:%m,%f:%l:%m
  set grepprg=rg\ -S\ --vimgrep\ --no-ignore-vcs\ --no-heading\ --hidden\ -g\ !tags
endif

let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_sign_info = '·'
let g:ale_sign_style_error = '·'
let g:ale_sign_style_warning = '·'

let g:ale_linters = { 'cs': ['OmniSharp'] }

let g:sharpenup_map_prefix = '<leader>'
let g:sharpenup_statusline_opts = { 'Text': '%s (%p/%P)' }
let g:sharpenup_statusline_opts.Highlight = 0

augroup _omnisharp_settings
    autocmd!
    autocmd User OmniSharpProjectUpdated,OmniSharpReady call lightline#update()
augroup END

let g:lightline = {
\ 'colorscheme': 'dracula',
\ 'active': {
\   'right': [
\     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok'],
\     ['lineinfo'], ['percent'],
\     ['fileformat', 'fileencoding', 'filetype', 'sharpenup', 'cocstatus']
\   ]
\ },
\ 'component': {
\   'sharpenup': sharpenup#statusline#Build()
\ },
\ 'component_function': {
\   'cocstatus': 'coc#status'
\ },
\ 'inactive': {
\   'right': [['lineinfo'], ['percent']]
\ },
\ 'component_expand': {
\   'linter_checking': 'lightline#ale#checking',
\   'linter_infos': 'lightline#ale#infos',
\   'linter_warnings': 'lightline#ale#warnings',
\   'linter_errors': 'lightline#ale#errors',
\   'linter_ok': 'lightline#ale#ok'
  \  },
  \ 'component_type': {
  \   'linter_checking': 'right',
  \   'linter_infos': 'right',
  \   'linter_warnings': 'warning',
  \   'linter_errors': 'error',
  \   'linter_ok': 'right'
\  }
\}
" Use unicode chars for ale indicators in the statusline
let g:lightline#ale#indicator_checking = "\uf110 "
let g:lightline#ale#indicator_infos = "\uf129 "
let g:lightline#ale#indicator_warnings = "\uf071 "
let g:lightline#ale#indicator_errors = "\uf05e "
let g:lightline#ale#indicator_ok = "\uf00c "


let g:OmniSharp_popup_position = 'peek'
let g:OmniSharp_popup_options = {
	\ 'highlight': 'Normal',
  \ 'padding': [1],
  \ 'border': [1],
  \ 'borderchars': [ '─','│','─','│', '╭',  '╮',  '╯',  '╰', ]
\}
let g:OmniSharp_popup_mappings = {
	\ 'sigNext': '<C-n>',
	\ 'sigPrev': '<C-p>',
	\ 'pageDown': ['<C-f>', '<PageDown>'],
	\ 'pageUp': ['<C-b>', '<PageUp>']
\}

" let g:OmniSharp_want_snippet = 1

let g:OmniSharp_highlight_groups = {
    \ 'ExcludedCode': 'NonText'
\}

let g:coc_global_extensions = [ 
	\ 'coc-json', 'coc-pyright', 'coc-vimlsp', 'coc-java', 'coc-rust-analyzer',
	\ 'coc-fzf-preview', 'coc-marketplace', 'coc-snippets'
	\]
let g:coc_data_home = expand(g:vim_dir . '/coc')
let g:coc_config_home = g:coc_data_home

highlight link CocHighlightText CocUnderline

nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <c-@> coc#refresh()

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
    \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

nmap <leader>rn <Plug>(coc-rename)
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup _coc_settings
  autocmd!
  autocmd CursorHold * silent call CocActionAsync('highlight')
  autocmd FileType typescript,json,java,csharp setlocal formatexpr=CocAction('formatSelected')
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>ac  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)
nmap <leader>cl  <Plug>(coc-codelens-action)

xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

command! -nargs=0 Format :call CocActionAsync('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OrganizeImports :call CocActionAsync('runCommand', 'editor.action.organizeImport')
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

" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

nnoremap <silent><nowait> <leader>cd  :<C-u>CocList diagnostics<cr>
nnoremap <silent><nowait> <leader>ce  :<C-u>CocList extensions<cr>
nnoremap <silent><nowait> <leader>cc  :<C-u>CocList commands<cr>
nnoremap <silent><nowait> <leader>cc  :<C-u>CocList commands<cr>
nnoremap <silent><nowait> <leader>co  :<C-u>CocList outline<cr>
nnoremap <silent><nowait> <leader>cm :<C-u>CocList marketplace<cr>
nnoremap <silent><nowait> <leader>cs  :<C-u>CocList -I symbols<cr>
nnoremap <silent><nowait> <leader>cn  :<C-u>CocNext<CR>
nnoremap <silent><nowait> <leader>cp  :<C-u>CocPrev<CR>
nnoremap <silent><nowait> <leader>cr  :<C-u>CocListResume<CR>
