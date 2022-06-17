local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local settings = augroup('user_settings', { clear = true })
local version = vim.version()

autocmd('User', {
    group = settings,
    desc = 'Removes tabline from Alpha buffer',
    pattern = 'AlphaReady',
    command = 'set showtabline=0 | autocmd BufLeave <buffer> set showtabline=' .. vim.opt.showtabline._value,
})

autocmd('User', {
    group = settings,
    desc = 'Removes statusline from Alpha buffer',
    pattern = 'AlphaReady',
    command = 'set laststatus=0 | autocmd BufLeave <buffer> set laststatus=' .. vim.opt.laststatus._value,
})

autocmd('User', {
    group = settings,
    desc = 'Removes winbar from Alpha buffer via AlphaReady event',
    pattern = 'AlphaReady',
    callback = function()
        local version = vim.version()
        if version.major > 0 or version.minor >= 8 then
            vim.opt.winbar = nil
        end
    end
})

if version.major > 0 or version.minor >= 8 then
    local ok, winbar = pcall(require, 'user.winbar')
    if not ok then
        vim.notify(string.format('user.autocommands -> Unable to import user.winbar; %s', winbar), vim.log.levels.ERROR)
        return
    end
    winbar.setup()
    if winbar.err then
        vim.notify(string.format('user.autocommands -> Unable to setup winbar %s', vim.inspect(winbar.err)), vim.log.levels.ERROR)
        return
    end
    autocmd({ 'BufEnter', 'BufWinEnter' }, {
        group = settings,
        desc = 'Adds winbar based on ft',
        callback = function()
            winbar.eval()
        end
    })
end

vim.cmd([[
    augroup _general_settings
        autocmd!
        autocmd FileType qf,help,man,lspinfo,null-ls-info,dap-float,git nnoremap <silent> <buffer> q :close<CR>
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
