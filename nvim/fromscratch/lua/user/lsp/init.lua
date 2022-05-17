local status_ok, lspconfig = pcall(require, 'lspconfig')
if not status_ok then
    return
end

local global_capabilities = vim.lsp.protocol.make_client_capabilities()
global_capabilities.textDocument.completion.completionItem.snippetSupport = true
global_capabilities.workspace.configuration = true

lspconfig.util.default_config = vim.tbl_extend('force', lspconfig.util.default_config, {
    capabilities = global_capabilities,
})

vim.lsp.set_log_level('info')
if vim.fn.has('nvim-0.5.1') == 1 then
    require('vim.lsp.log').set_format_func(vim.inspect)
end

require('user.lsp.configs')
require('user.lsp.handlers').setup()
require('user.lsp.null-ls')
