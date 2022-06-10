local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local settings = augroup('user_settings', { clear = true })

autocmd("User", {
    group = settings,
    pattern = "AlphaReady",
    command = "set showtabline=0 | autocmd BufLeave <buffer> set showtabline=" .. vim.opt.showtabline._value,
})

autocmd("User", {
    group = settings,
    pattern = "AlphaReady",
    command = "set laststatus=0 | autocmd BufLeave <buffer> set laststatus=" .. vim.opt.laststatus._value,
})

vim.cmd([[
    augroup _general_settings
        autocmd!
        autocmd FileType qf,help,man,lspinfo,null-ls-info,dap-float nnoremap <silent> <buffer> q :close<CR>
        autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Search', timeout = 200})
        autocmd BufWinEnter * :set formatoptions-=cro
        autocmd FileType qf set nobuflisted
    augroup end

    augroup _auto_resize
        autocmd!
        autocmd VimResized * tabdo wincmd =
    augroup end

    augroup _terminal
        autocmd!
        autocmd TermOpen,TermEnter term://* startinsert!
        autocmd TermEnter term://* setlocal nonumber norelativenumber signcolumn=no
    augroup end
]])
