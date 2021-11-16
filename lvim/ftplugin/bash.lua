local formatters = require('lvim.lsp.null-ls.formatters')
formatters.setup({ { exe = 'shellharden', filetypes = { 'bash', 'sh' } } })

local linters = require('lvim.lsp.null-ls.linters')
linters.setup({ { exe = 'shellcheck', filetypes = { 'bash', 'sh' } } })
