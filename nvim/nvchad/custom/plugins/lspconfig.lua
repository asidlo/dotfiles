local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

local servers = {"sumneko_lua", "omnisharp"}

for _, lsp in ipairs(servers) do
  local opts = {
    on_attach = on_attach,
    capabilities = capabilities,
  }
  local has_custom_opts, server_custom_opts = pcall(require, 'custom.plugins.settings.' .. lsp)
  if has_custom_opts then
      opts = vim.tbl_deep_extend('force', server_custom_opts, opts)
  end
  lspconfig[lsp].setup(opts)
end
