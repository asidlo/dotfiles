local status_ok, lsp_installer = pcall(require, 'nvim-lsp-installer')
if not status_ok then
  return
end

local lspconfig = require('lspconfig')

-- 'jsonls',
-- 'sumneko_lua',
-- 'bicep',
-- 'clangd',
-- 'cmake',
-- 'bashls',
-- 'dockerls',
-- 'gopls',
-- 'jdtls',
-- 'omnisharp',
-- 'pyright',
-- 'rust_analyzer',
local servers = {}
if vim.env.LSP_SERVERS ~= nil then
  servers = vim.fn.split(vim.env.LSP_SERVERS, ',')
end

local server_dir = vim.fn.glob('~/.local/share/nvim/lsp_servers')
if vim.fn.empty(server_dir) == 0 then
  local cmd = 'fd -t d -d 1 -E "*.tmp" . ' .. server_dir .. ' -x echo {/}'
  servers = vim.tbl_extend('force', servers, vim.fn.systemlist(cmd))
end

if #vim.api.nvim_list_uis() == 0 then
    servers = {}
end

vim.env.LSP_SERVERS_INSTALLED = vim.fn.join(servers, ',')

lsp_installer.setup({
  ensure_installed = servers,
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
