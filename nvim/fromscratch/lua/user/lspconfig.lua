local status_ok, lspconfig = pcall(require, 'lspconfig')
if not status_ok then
    return
end

local win = require('lspconfig.ui.windows')
local _default_opts = win.default_opts

win.default_opts = function(options)
  local opts = _default_opts(options)
  opts.border = 'rounded'
  return opts
end

local global_capabilities = vim.lsp.protocol.make_client_capabilities()
global_capabilities.workspace.configuration = true
global_capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}
lspconfig.util.default_config = vim.tbl_extend('force', lspconfig.util.default_config, {
    capabilities = global_capabilities
})

vim.lsp.set_log_level('warn')
-- if vim.fn.has('nvim-0.5.1') == 1 then
--     require('vim.lsp.log').set_format_func(vim.inspect)
-- end

require('user.lsp.handlers').setup()
