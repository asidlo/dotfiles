" install: curl https://raw.githubusercontent.com/prabirshrestha/vim-lsp/master/minimal.vimrc -o /tmp/minimal.vimrc
" uninstall: rm /tmp/plug.vim && rm -rf /tmp/plugged
" run vim/neovim with minimal.vimrc
" vim -u minimal.vimrc
" :PlugInstall

set nocompatible hidden laststatus=2

if !filereadable('/tmp/plug.vim')
  silent !curl --insecure -fLo /tmp/plug.vim
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

source /tmp/plug.vim

call plug#begin('/tmp/plugged')
Plug 'prabirshrestha/vim-lsp'
call plug#end()

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('/tmp/vim-lsp.log')

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    setlocal formatexpr=lsp#ui#vim#document_range_format_sync()
    setlocal foldmethod=expr
      \ foldexpr=lsp#ui#vim#folding#foldexpr()
      \ foldtext=lsp#ui#vim#folding#foldtext()
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> K <plug>(lsp-hover)
    nmap <buffer> <f2> <plug>(lsp-rename)
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

let g:eclipse_dir = expand('/tmp/lsp/eclipse.jdt.ls/latest')
let g:eclipse_jar = g:eclipse_dir . '/plugins/org.eclipse.equinox.launcher_1.5.700.v20200207-2156.jar'

if executable('java') && filereadable(g:eclipse_jar)
    autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'eclipse.jdt.ls',
        \ 'cmd': {server_info->[
        \     'java',
        \     '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        \     '-Dosgi.bundles.defaultStartLevel=4',
        \     '-Declipse.product=org.eclipse.jdt.ls.core.product',
        \     '-Dlog.protocol=true',
        \     '-Dlog.level=ALL',
        \     '-noverify',
        \     '-Dfile.encoding=UTF-8',
        \     '-Xmx1G',
        \     '-javaagent:/Users/asidlo/.local/share/vim-lsp-settings/servers/eclipse-jdt-ls/lombok.jar',
        \     '-Xbootclasspath/a:/Users/asidlo/.local/share/vim-lsp-settings/servers/eclipse-jdt-ls/lombok.jar',
        \     '-jar',
        \     '/tmp/lsp/eclipse.jdt.ls/latest/plugins/org.eclipse.equinox.launcher_1.5.700.v20200207-2156.jar', 
        \     '-configuration',
        \     '/tmp/lsp/eclipse.jdt.ls/latest/config_mac',
        \     '-data',
        \     '/tmp/lsp/data',
        \     '--add-modules=ALL-SYSTEM',
        \     '--add-opens java.base/java.util=ALL-UNNAMED',
        \     '--add-opens java.base/java.lang=ALL-UNNAMED'
        \ ]},
        \ 'whitelist': ['java'],
        \ })
endif

if executable('rls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
        \ 'workspace_config': {'rust': {'clippy_preference': 'on'}},
        \ 'whitelist': ['rust'],
        \ })
endif
