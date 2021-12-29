local status_ok, lsp_installer = pcall(require, 'nvim-lsp-installer')
if not status_ok then
    return
end

local path_ok, path = pcall(require, 'nvim-lsp-installer.path')
if not path_ok then
    return
end

local install_root_dir = path.concat {vim.fn.stdpath 'data', 'lsp_servers'}

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
    local opts = {
        on_attach = require('user.lsp.handlers').on_attach,
        capabilities = require('user.lsp.handlers').capabilities,
    }

    if server.name == 'jsonls' then
        local jsonls_opts = require('user.lsp.settings.jsonls')
        opts = vim.tbl_deep_extend('force', jsonls_opts, opts)
    end

    if server.name == 'sumneko_lua' then
        local sumneko_opts = require('user.lsp.settings.sumneko_lua')
        opts = vim.tbl_deep_extend('force', sumneko_opts, opts)
    end

    if server.name == 'jdtls' then
        return
    end

    if server.name == 'gopls' then
        local go_ok, go_lsp = pcall(require, 'go.lsp')
        if not go_ok then
            return
        end
        -- Initialize the LSP via rust-tools instead
        local go_opts = go_lsp.config()
        opts = vim.tbl_deep_extend('force', go_opts, opts)

        opts.cmd = {install_root_dir .. '/go/gopls', '-remote=auto'}
    end

    if server.name == 'rust_analyzer' then
        local rtools_ok, rtools = pcall(require, 'rust-tools')
        if not rtools_ok then
            return
        end
        -- Initialize the LSP via rust-tools instead
        rtools.setup({
            -- The "server" property provided in rust-tools setup function are the
            -- settings rust-tools will provide to lspconfig during init.
            -- We merge the necessary settings from nvim-lsp-installer (server:get_default_options())
            -- with the user's own settings (opts).
            server = vim.tbl_deep_extend('force', server:get_default_options(), opts),
        })
        server:attach_buffers()
        return
    end

    -- This setup() function is exactly the same as lspconfig's setup function.
    -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
    server:setup(opts)
end)
