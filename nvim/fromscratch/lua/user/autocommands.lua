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

if version.major > 0 or version.minor >= 8 then
    autocmd('User', {
        group = settings,
        desc = 'Removes winbar from Alpha buffer via AlphaReady event',
        pattern = 'AlphaReady',
        callback = function()
            vim.opt.winbar = nil
        end
    })
end

if version.major > 0 or version.minor >= 8 then
    local ok, winbar = pcall(require, 'user.winbar')
    if not ok then
        vim.notify(string.format('user.autocommands -> Unable to import user.winbar; %s', winbar), vim.log.levels.ERROR)
        return
    end
    winbar.setup()
    if winbar.err then
        vim.notify(string.format('user.autocommands -> Unable to setup winbar %s', vim.inspect(winbar.err)),
            vim.log.levels.ERROR)
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

local buf_keymap = vim.api.nvim_buf_set_keymap
local opts = { noremap = true, silent = true }

autocmd({ 'FileType' }, {
    group = settings,
    pattern = 'qf,help,man,lspinfo,null-ls-info,dap-float,git,notify',
    desc = 'Closes buffer with q',
    callback = function(tbl)
        local bufnr = tbl.buf
        buf_keymap(bufnr, 'n', 'q', '<Cmd>close<CR>', opts)
    end
})

autocmd({ 'TextYankPost' }, {
    group = settings,
    desc = 'Highlight yanked text',
    callback = function()
        local ok, hl = pcall(require, 'vim.highlight')
        if not ok then
            return
        end
        hl.on_yank({ higroup = 'Search', timeout = 200 })
    end
})

autocmd({ 'FileType' }, {
    group = settings,
    pattern = 'qf',
    desc = 'Remove qf from buffer list',
    callback = function()
        vim.opt_local.buflisted = false
    end
})

autocmd({ 'VimResized' }, {
    group = settings,
    desc = 'Auto resize',
    callback = function()
        vim.cmd('tabdo wincmd =')
    end
})

autocmd({ 'TermOpen', 'TermEnter' }, {
    group = settings,
    pattern = 'term://*',
    desc = 'Start terminal in insert mode',
    callback = function()
        vim.cmd('startinsert!')
    end
})

autocmd({ 'TermEnter' }, {
    group = settings,
    pattern = 'term://*',
    desc = 'Change terminal settings',
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
    end
})
