vim.cmd('setlocal expandtab tabstop=2 shiftwidth=2')
vim.cmd('setlocal textwidth=79')

local formatters = require('lvim.lsp.null-ls.formatters')
formatters.setup({ { exe = 'prettierd' } })

local linters = require('lvim.lsp.null-ls.linters')
linters.setup({
    {
        exe = 'markdownlint',
        args = { '-c', os.getenv('HOME') .. '/.markdownlint.json' },
    },
    { exe = 'vale' },
})
