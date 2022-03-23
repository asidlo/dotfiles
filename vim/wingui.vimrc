if has("gui_running")
    set guifont=MesloLGM_NF:h12
    set guioptions-=m
    set guioptions-=T
    set guioptions-=l
    set guioptions-=L
    set guioptions-=R

    set number

    let g:vim_dir = expand('~/vimfiles')

    if empty(glob(g:vim_dir . '/autoload/plug.vim'))
        let g:vim_plug_uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        let g:vim_plug_powershell_download_cmd = 'Invoke-WebRequest -Uri "' . g:vim_plug_uri . '" -OutFile "' . expand(g:vim_dir . '/autoload/plug.vim') . '"'
        silent execute '!powershell -command New-Item -ItemType Directory -Path "' . expand(g:vim_dir . '/autoload') . '"'
        silent execute '!powershell -command ' . g:vim_plug_powershell_download_cmd
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif

    " Set this to 1 to use ultisnips for snippet handling
    let s:using_snippets = 0

    " vim-plug: {{{
    call plug#begin(expand(g:vim_dir . '/plugged'))

    Plug 'OmniSharp/omnisharp-vim'

    " Mappings, code-actions available flag and statusline integration
    Plug 'nickspoons/vim-sharpenup'

    " Linting/error highlighting
    Plug 'dense-analysis/ale'

    " Vim FZF integration, used as OmniSharp selector
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'

    " Autocompletion
    Plug 'prabirshrestha/asyncomplete.vim'

    " Colorscheme
    Plug 'gruvbox-community/gruvbox'

    " Statusline
    Plug 'itchyny/lightline.vim'
    Plug 'shinchu/lightline-gruvbox.vim'
    Plug 'maximbaz/lightline-ale'

    " Snippet support
    if s:using_snippets
    Plug 'sirver/ultisnips'
    endif

    call plug#end()
    " }}}

    " Settings: {{{
    filetype indent plugin on
    if !exists('g:syntax_on') | syntax enable | endif
    set encoding=utf-8
    scriptencoding utf-8


    set completeopt=menuone,noinsert,noselect,popuphidden
    set completepopup=highlight:Pmenu,border:off

    set backspace=indent,eol,start
    set expandtab
    set shiftround
    set shiftwidth=4
    set softtabstop=-1
    set tabstop=8
    set textwidth=80
    set title

    set hidden
    set nofixendofline
    set nostartofline
    set splitbelow
    set splitright

    set hlsearch
    set incsearch
    set laststatus=2
    set nonumber
    set noruler
    set noshowmode
    set signcolumn=yes

    set mouse=a
    set updatetime=1000
    " }}}

    " Colors: {{{
     augroup ColorschemePreferences
       autocmd!
       " These preferences clear some gruvbox background colours, allowing transparency
       " autocmd ColorScheme * highlight Normal     ctermbg=NONE guibg=NONE
       autocmd ColorScheme * highlight SignColumn ctermbg=NONE guibg=NONE
       autocmd ColorScheme * highlight Todo       ctermbg=NONE guibg=NONE
       " Link ALE sign highlights to similar equivalents without background colours
       autocmd ColorScheme * highlight link ALEErrorSign   WarningMsg
       autocmd ColorScheme * highlight link ALEWarningSign ModeMsg
       autocmd ColorScheme * highlight link ALEInfoSign    Identifier
     augroup END

    " Use truecolor in the terminal, when it is supported
    if has('termguicolors')
    set termguicolors
    endif

    set background=dark
    colorscheme gruvbox
    " }}}

    " ALE: {{{
    let g:ale_sign_error = '•'
    let g:ale_sign_warning = '•'
    let g:ale_sign_info = '·'
    let g:ale_sign_style_error = '·'
    let g:ale_sign_style_warning = '·'

    let g:ale_linters = { 'cs': ['OmniSharp'] }
    " }}}

    " Asyncomplete: {{{
    let g:asyncomplete_auto_popup = 1
    let g:asyncomplete_auto_completeopt = 0
    " }}}

    " Sharpenup: {{{
    " All sharpenup mappings will begin with `<Space>os`, e.g. `<Space>osgd` for
    " :OmniSharpGotoDefinition
    let g:sharpenup_map_prefix = '<Space>os'

    let g:sharpenup_statusline_opts = { 'Text': '%s (%p/%P)' }
    let g:sharpenup_statusline_opts.Highlight = 0

    augroup OmniSharpIntegrations
    autocmd!
    autocmd User OmniSharpProjectUpdated,OmniSharpReady call lightline#update()
    augroup END
    " }}}

    " Lightline: {{{
    let g:lightline = {
    \ 'colorscheme': 'gruvbox',
    \ 'active': {
    \   'right': [
    \     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok'],
    \     ['lineinfo'], ['percent'],
    \     ['fileformat', 'fileencoding', 'filetype', 'sharpenup']
    \   ]
    \ },
    \ 'inactive': {
    \   'right': [['lineinfo'], ['percent'], ['sharpenup']]
    \ },
    \ 'component': {
    \   'sharpenup': sharpenup#statusline#Build()
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
    " }}}

    " OmniSharp: {{{
    let g:OmniSharp_popup_position = 'peek'
    if has('nvim')
    let g:OmniSharp_popup_options = {
    \ 'winhl': 'Normal:NormalFloat'
    \}
    else
    let g:OmniSharp_popup_options = {
    \ 'highlight': 'Normal',
    \ 'padding': [0, 0, 0, 0],
    \ 'border': [1]
    \}
    endif
    let g:OmniSharp_popup_mappings = {
    \ 'sigNext': '<C-n>',
    \ 'sigPrev': '<C-p>',
    \ 'pageDown': ['<C-f>', '<PageDown>'],
    \ 'pageUp': ['<C-b>', '<PageUp>']
    \}

    if s:using_snippets
    let g:OmniSharp_want_snippet = 1
    endif

    let g:OmniSharp_highlight_groups = {
    \ 'ExcludedCode': 'NonText'
    \}
    " }}}
endif
