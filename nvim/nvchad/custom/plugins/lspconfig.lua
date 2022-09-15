local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

local servers = { "sumneko_lua", "omnisharp" }

local on_attach_override = function(client, bufnr)
  on_attach(client, bufnr)
  if vim.g.vim_version > 7 then
    -- nightly
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
  else
    -- stable
    client.resolved_capabilities.document_formatting = true
    client.resolved_capabilities.document_range_formatting = true
  end
end

for _, lsp in ipairs(servers) do
  local opts = {
    on_attach = on_attach_override,
    capabilities = capabilities,
  }
  local has_custom_opts, server_custom_opts = pcall(require, 'custom.plugins.settings.' .. lsp)
  if has_custom_opts then
    opts = vim.tbl_deep_extend('force', server_custom_opts, opts)
  end
  lspconfig[lsp].setup(opts)
end
