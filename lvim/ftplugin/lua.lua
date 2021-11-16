vim.cmd('setlocal expandtab tabstop=4 shiftwidth=4')

local formatters = require('lvim.lsp.null-ls.formatters')
formatters.setup({
    {
        exe = 'stylua',
        args = {
            '--indent-width',
            '4',
            '--quote-style',
            'AutoPreferSingle',
            '--indent-type',
            'Spaces',
        },
    },
})

local linters = require('lvim.lsp.null-ls.linters')
linters.setup({
    {
        exe = 'luacheck',
        args = { '--globals', 'lvim', '--globals', 'vim' },
    },
})
