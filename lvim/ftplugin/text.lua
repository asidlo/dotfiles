vim.cmd('setlocal expandtab tabstop=4 shiftwidth=4')
vim.cmd('setlocal textwidth=79')
vim.cmd('setlocal spell')

local linters = require('lvim.lsp.null-ls.linters')
linters.setup({ { exe = 'vale' } })
