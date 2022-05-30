local status_ok, lsp_installer = pcall(require, 'nvim-lsp-installer')
if not status_ok then
    return
end

local lspconfig = require('lspconfig')

local servers = {
    'jsonls',
    'sumneko_lua',
    'bicep',
    'clangd',
    'cmake',
    'bashls',
    'dockerls',
    'gopls',
    'jdtls',
    'omnisharp',
    'pyright',
    'rust_analyzer',
}

lsp_installer.setup({
    ensure_installed = {},
})

for _, server in pairs(servers) do
    local opts = {
        on_attach = require('user.lsp.handlers').on_attach,
        capabilities = require('user.lsp.handlers').capabilities,
    }
    local has_custom_opts, server_custom_opts = pcall(require, 'user.lsp.settings.' .. server)
    if has_custom_opts then
        opts = vim.tbl_deep_extend('force', server_custom_opts, opts)
    end
    lspconfig[server].setup(opts)
end

-- lspconfig.omnisharp.setup({
--     cmd = {
--         'dotnet',
--         -- '/home/asidlo/.local/share/nvim/lsp_servers/omnisharp/omnisharp/OmniSharp.dll',
--         '/home/asidlo/omnisharp6/OmniSharp.dll',
--         '--languageserver',
--         '-z',
--         -- '-s',
--         -- '/home/asidlo/workspace/src/msft/Networking-AppGW/src/ApplicationGateway.sln',
--         '--hostPID',
--         tostring(vim.fn.getpid()),
--         'DotNet:enablePackageRestore=false',
--         '--encoding',
--         'utf-8',
--         '--loglevel',
--         'information',
--     },
--     handlers = {
--         ['textDocument/definition'] = require('omnisharp_extended').handler,
--     },
--     on_attach = require('user.lsp.handlers').on_attach,
--     capabilities = require('user.lsp.handlers').capabilities,
-- })
