vim.cmd([[
    augroup _general_settings
        autocmd!
        autocmd FileType qf,help,man,lspinfo,null-ls-info nnoremap <silent> <buffer> q :close<CR> 
        autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Search', timeout = 200}) 
        autocmd BufWinEnter * :set formatoptions-=cro
        autocmd FileType qf set nobuflisted
    augroup end

    augroup _git
        autocmd!
        autocmd FileType gitcommit setlocal wrap
        autocmd FileType gitcommit setlocal spell
    augroup end

    augroup _markdown
        autocmd!
        autocmd FileType markdown setlocal wrap
        autocmd FileType markdown setlocal spell
    augroup end

    augroup _auto_resize
        autocmd!
        autocmd VimResized * tabdo wincmd = 
    augroup end

    augroup _alpha
        autocmd!
        autocmd User AlphaReady set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
    augroup end

    augroup _terminal
        autocmd!
        autocmd TermOpen,TermEnter term://* startinsert!
        autocmd TermEnter term://* setlocal nonumber norelativenumber signcolumn=no
    augroup end
]])
