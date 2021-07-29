local jdtls = require('jdtls')
local M = {}

local on_attach = function(client, bufnr)
    -- local cfg = {bind = true, use_lspsaga = true}
    require'jdtls.setup'.add_commands()
    require'jdtls'.setup_dap()
    require('lsp_signature').on_attach()
    require('lspkind').init()
    set_buf_keymap(bufnr, 'n', 'gR', '<Cmd>lua vim.lsp.buf.rename()<CR>')
    set_buf_keymap(bufnr, 'n', '<M-CR>', "<Cmd>lua require('jdtls').code_action()<CR>")
    set_buf_keymap(bufnr, 'v', '<M-CR>', "<Esc><Cmd>lua require('jdtls').code_action(true)<CR>")
    set_buf_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
    set_buf_keymap(bufnr, 'n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>')
    set_buf_keymap(bufnr, 'n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>')
    set_buf_keymap(bufnr, 'n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>')
    set_buf_keymap(bufnr, 'n', 'gt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>')
    set_buf_keymap(bufnr, 'n', 'g0', '<Cmd>Telescope lsp_document_symbols<CR>')
    set_buf_keymap(bufnr, 'n', '<Leader>ws', '<Cmd>Telescope lsp_workspace_symbols<CR>')
    set_buf_keymap(bufnr, 'n', '<Leader>wl', '<Cmd>lua dump(vim.lsp.buf.list_workspace_folders())<CR>')
    set_buf_keymap(bufnr, 'n', 'K', "<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>")
    set_buf_keymap(bufnr, 'i', '<M-k>', "<Cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>")

    set_buf_keymap(bufnr, 'n', '[d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
    set_buf_keymap(bufnr, 'n', ']d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
    set_buf_keymap(bufnr, 'n', '<M-Space>', "<Cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>")
    set_buf_keymap(bufnr, 'n', 'gK', "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>")
    set_buf_keymap(bufnr, 'n', '<M-d>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>")
    set_buf_keymap(bufnr, 'n', '<M-u>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>")

    if client.resolved_capabilities.document_range_formatting then
        -- Note that v:lua only supports global functions
        vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end

    if client.resolved_capabilities.document_formatting then
        set_buf_keymap(0, 'n', 'g=', '<Cmd>lua vim.lsp.buf.formatting()<CR>')
    end

    if client.name == 'jdtls' then
        set_buf_keymap(bufnr, 'n', '<M-o>', '<Cmd>lua require("lsp.jdtls").organize_imports()<CR>')
    end

    vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics,
                                                                       {update_in_insert = true})

    -- Set autocommands conditional on server_capabilities
    if client.resolved_capabilities.document_highlight then
        vim.api.nvim_command [[
            :hi LspReferenceRead guibg=NONE gui=underline term=underline cterm=underline
            :hi LspReferenceText guibg=NONE gui=underline term=underline cterm=underline
            :hi LspReferenceWrite guibg=NONE gui=underline term=underline cterm=underline
        ]]
        nvim_create_augroups({
            lsp_document_highlight = {
                {'CursorHold <buffer> lua vim.lsp.buf.document_highlight()'},
                {'CursorMoved <buffer> lua vim.lsp.buf.clear_references()'}
            }
        })
    end
end

local home = os.getenv('HOME')

local jar_patterns = {
    home .. '/.local/src/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
    home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.plugin/target/*.jar',
    home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.runner/target/*.jar',
    home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.runner/lib/*.jar'
}

local bundles = {}
for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
        if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') then table.insert(bundles, bundle) end
    end
end

local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

function M.start_or_attach()
    local config = {
        cmd = {'jdtls.sh', home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")},
        flags = {allow_incremental_sync = true, server_side_fuzzy_completion = true},
        capabilities = {
            workspace = {configuration = true},
            textDocument = {completion = {completionItem = {snippetSupport = true}}}
        },
        on_attach = on_attach,
        init_options = {bundles = bundles, extendedClientCapabilities = extendedClientCapabilities},
        settings = {
            java = {
                signatureHelp = {enabled = true},
                contentProvider = {preferred = 'fernflower'},
                format = {insertSpaces = true, tabSize = 4},
                completion = {
                    favoriteStaticMembers = {
                        "org.hamcrest.MatcherAssert.assertThat", "org.hamcrest.Matchers.*",
                        "org.hamcrest.CoreMatchers.*", "org.junit.jupiter.api.Assertions.*",
                        "java.util.Objects.requireNonNull", "java.util.Objects.requireNonNullElse",
                        "org.mockito.Mockito.*"
                    }
                },
                sources = {organizeImports = {starThreshold = 9999, staticStarThreshold = 9999}},
                codeGeneration = {
                    toString = {template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"}
                },
                configuration = {
                    runtimes = {
                        {name = 'JavaSE-11', path = home .. '/.sdkman/candidates/java/11.0.11-zulu/', default = true}
                        -- {name = 'JavaSE-1.8', path = home .. '/.sdkman/candidates/java/8.0.292-zulu'}
                    }
                }
            }
        }
    }
    config.on_init = function(client, _)
        client.notify('workspace/didChangeConfiguration', {settings = config.settings})
    end

    jdtls.start_or_attach(config)
end

return M
