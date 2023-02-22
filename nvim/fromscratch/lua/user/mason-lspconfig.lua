local mason_present, mason_lspconfig = pcall(require, "mason-lspconfig")
local lspconf_present, lspconfig = pcall(require, "lspconfig")

if not mason_present or not lspconf_present then
  return
end

mason_lspconfig.setup()

mason_lspconfig.setup_handlers {
  function (server_name)
    local has_custom_opts, server_custom_opts = pcall(require, 'user.lsp.settings.' .. server_name)
    local opts = lspconfig.util.default_config
    if has_custom_opts then
        opts = vim.tbl_deep_extend('force', server_custom_opts, opts)
    end
    opts.on_attach = require('user.lsp.handlers').on_attach
    lspconfig[server_name].setup(opts)
  end
}
