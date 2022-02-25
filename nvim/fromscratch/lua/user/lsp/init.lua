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

-- vim.lsp.set_log_level('trace')
-- if vim.fn.has('nvim-0.5.1') == 1 then
--     require('vim.lsp.log').set_format_func(vim.inspect)
-- end

local path = require('nvim-lsp-installer.path')
local install_root_dir = path.concat({ vim.fn.stdpath('data'), 'lsp_servers' })

lspconfig.omnisharp.setup({
    cmd = {
        install_root_dir .. '\\omnisharp\\omnisharp\\OmniSharp.exe',
        '--languageserver',
        '--hostPID',
        tostring(vim.fn.getpid()),
        'roslynExtensionsOptions:enableAnalyzersSupport=true',
        'formattingOptions:enableEditorConfigSupport=true',
        'roslynExtensionsOptions:enableDecompilationSupport=true',
        'roslynExtensionsOptions:enableImportCompletion=true'
    },
    on_attach = require('user.lsp.handlers').on_attach,
    capabilities = require('user.lsp.handlers').capabilities,
})

require('user.lsp.lsp-installer')
require('user.lsp.handlers').setup()
require('user.lsp.null-ls')
