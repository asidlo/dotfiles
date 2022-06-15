local status_ok, lsp_installer = pcall(require, 'nvim-lsp-installer')
if not status_ok then
    return
end

local lspconfig = require('lspconfig')

-- Env variable should override all values. If a user specifies lsps via the
-- env var, then ensure those are installed and configured
local servers = {}
if vim.env.LSP_SERVERS ~= nil then
    local server_names = vim.fn.split(vim.env.LSP_SERVERS, ',')
    for _, server_name in ipairs(server_names) do
        servers[server_name] = true
    end
end

-- Merge installed lsps + to be installed to ensure all are configured
local available_servers = require('nvim-lsp-installer.servers').get_installed_server_names()
for _, server in ipairs(available_servers) do
    servers[server] = true
end

-- No need to install lsps when running headless.
-- Specific command will be used instead.
if #vim.api.nvim_list_uis() == 0 then
    servers = {}
end

local server_names = vim.tbl_keys(servers)
vim.env.LSP_SERVERS_INSTALLED = vim.fn.join(server_names, ',')

lsp_installer.setup({
    ensure_installed = server_names,
})

for _, server in pairs(server_names) do
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
