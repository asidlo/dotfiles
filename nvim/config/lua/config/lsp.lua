local lspconfig = require('lspconfig')
local jdtls = require('jdtls')

local M = {}

-- Until they release the `vim.lsp.util.formatexpr()`
-- https://github.com/neovim/neovim/issues/12528
-- https://github.com/neovim/neovim/pull/12547
-- https://github.com/neovim/neovim/pull/13138
--
--- Implements an LSP `formatexpr`-compatible
-- @param start_line 1-indexed line, defaults to |v:lnum|
-- @param end_line 1-indexed line, calculated based on {start_line} and |v:count|
-- @param timeout_ms optional, defaults to 500ms
function _G.lsp_formatexpr(start_line, end_line, timeout_ms)
    timeout_ms = timeout_ms or 500

    if not start_line or not end_line then
        if vim.fn.mode() == 'i' or vim.fn.mode() == 'R' then
            -- `formatexpr` is also called when exceeding `textwidth` in insert mode
            -- fall back to internal formatting
            return 1
        end
        start_line = vim.v.lnum
        end_line = start_line + vim.v.count - 1
    end

    if start_line > 0 and end_line > 0 then
        local end_char = vim.fn.col('$')
        vim.lsp.buf.range_formatting({}, {start_line, 0}, {end_line, end_char})
    end

    -- do not run builtin formatter.
    return 0
end

-- https://github.com/neovim/neovim/issues/14825
vim.g.diagnostics_visible = true

function _G.toggle_diagnostics()
    if vim.g.diagnostics_visible then
        vim.g.diagnostics_visible = false
        vim.lsp.diagnostic.clear(0)
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
        print('Diagnostics are hidden')
    else
        vim.g.diagnostics_visible = true
        vim.lsp.handlers["textDocument/publishDiagnostics"] =
            vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics,
                         {virtual_text = true, signs = true, underline = true, update_in_insert = false})
        print('Diagnostics are visible')
    end
end

local on_attach = function(client, bufnr)
    require('lsp_signature').on_attach({bind = true, use_lspsaga = true})
    require('lspkind').init()
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
    set_buf_keymap(bufnr, 'n', 'gR', "<Cmd>lua require('lspsaga.rename').rename()<CR>")
    set_buf_keymap(bufnr, 'n', '[d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
    set_buf_keymap(bufnr, 'n', ']d', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
    set_buf_keymap(bufnr, 'n', '<M-Space>', "<Cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>")
    set_buf_keymap(bufnr, 'n', 'gK', "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>")
    set_buf_keymap(bufnr, 'n', '<M-d>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>")
    set_buf_keymap(bufnr, 'n', '<M-u>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>")

    set_buf_keymap(bufnr, 'n', '<Leader>d', ':call v:lua.toggle_diagnostics()<CR>')

    if client.resolved_capabilities.document_range_formatting then
        -- Note that v:lua only supports global functions
        vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end

    if client.resolved_capabilities.document_formatting then
        set_buf_keymap(bufnr, 'n', 'g=', '<Cmd>lua vim.lsp.buf.formatting()<CR>')
    end

    if client.name == 'jdtls' then
        set_buf_keymap(bufnr, 'n', '<M-o>', "<Cmd>lua require('lsp.jdtls').organize_imports()<CR>")
        set_buf_keymap(bufnr, 'n', '<Leader>r', '<Cmd>lua vim.lsp.buf.rename()<CR>')
    end

    if client.name == 'jdt.ls' then
        require'jdtls.setup'.add_commands()
        require'jdtls'.setup_dap()
        set_buf_keymap(bufnr, 'n', '<M-CR>', "<Cmd>lua require('jdtls').code_action()<CR>")
        set_buf_keymap(bufnr, 'v', '<M-CR>', "<Esc><Cmd>lua require('jdtls').code_action(true)<CR>")
    elseif client.name == 'jdtls' then
        set_buf_keymap(bufnr, 'n', '<M-CR>', "<Cmd>lua vim.lsp.buf.code_action()<CR>")
        set_buf_keymap(bufnr, 'x', '<M-CR>', "<Cmd>'<,'>lua vim.lsp.buf.range_code_action()<CR>")
    else
        set_buf_keymap(bufnr, 'n', '<M-CR>', "<Cmd>lua require('lspsaga.codeaction').code_action()<CR>")
        set_buf_keymap(bufnr, 'x', '<M-CR>', "<Cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>")
    end

    vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics,
    --                                                                    {update_in_insert = true})

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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.workspace.configuration = true

-- vim.lsp.set_log_level('debug')

local extra_capabilities = {
    textDocument = {
        codeAction = {
            dataSupport = true,
            resolveSupport = {properties = {'edit'}},
            codeActionLiteralSupport = {
                codeActionKind = {
                    valueSet = {"source.generate.toString", "source.generate.hashCodeEquals", "source.organizeImports"}
                }
            }
        }
    }
}

-- https://github.com/neovim/neovim/issues/12970
vim.lsp.util.apply_text_document_edit = function(text_document_edit, _)
    local text_document = text_document_edit.textDocument
    local bufnr = vim.uri_to_bufnr(text_document.uri)

    vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr)
end

function M.setup_lspconfig()
    lspconfig.rust_analyzer.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {['rust-analyzer'] = {checkOnSave = {command = "clippy"}}}
    }
    -- require('rust-tools').setup({tools = {server = {on_attach = on_attach}}})

    -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#completion
    -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
    lspconfig.gopls.setup {
        on_attach = on_attach,
        -- cmd = {'gopls', '-remote=auto'},
        -- root_dir = lspconfig.util.root_pattern('go.mod', '.git', '*.go'),
        settings = {
            gopls = {
                experimentalPostfixCompletions = true,
                analyses = {unusedparams = true, shadow = true},
                staticcheck = true
            }
        },
        capabilities = capabilities
    }

    lspconfig.jsonls.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        commands = {Format = {function() vim.lsp.buf.range_formatting({}, {0, 0}, {vim.fn.line("$"), 0}) end}}
    }

    lspconfig.pyright.setup {on_attach = on_attach, capabilities = capabilities}

    local home = os.getenv('HOME')

    lspconfig.jdtls.setup {
        autostart = false,
        on_attach = on_attach,
        cmd = {'jdtls.sh', home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")},
        flags = {allow_incremental_sync = true, server_side_fuzzy_completion = true},
        handlers = {
            ['textDocument/codeAction'] = function(_, method, actions)
                -- new_buf({a, b, actions})
                for _, action in ipairs(actions) do
                    if action ~= vim.NIL then
                        if action.command.command == 'java.apply.workspaceEdit' then
                            local changes = {}
                            local documentChanges = {}
                            for _, argument in ipairs(action.command.arguments) do
                                for _, change in ipairs(argument.changes) do
                                    table.insert(changes, change)
                                end
                                if argument.documentChanges then
                                    for _, documentChange in ipairs(argument.documentChanges) do
                                        table.insert(documentChanges, documentChange)
                                    end
                                end
                            end
                            action.edit = {changes = changes, documentChanges = documentChanges}
                            action.command = nil
                        end
                    end
                end
                -- new_buf({a, b, actions})
                vim.lsp.handlers['textDocument/codeAction'](nil, method, actions)
            end
            -- ['textDocument/definition'] = function(_, method, params, client_id, bufnr, config)
            --     vim.lsp.handlers['textDocument/definition'](nil, method, params, client_id, bufnr, config)
            -- end
        },
        capabilities = capabilities, -- vim.tbl_deep_extend('keep', capabilities, extra_capabilities),
        init_options = {
            bundles = {},
            extendedClientCapabilities = {
                progressReportProvider = true,
                classFileContentsSupport = true,
                generateToStringPromptSupport = true,
                hashCodeEqualsPromptSupport = true,
                advancedExtractRefactoringSupport = true,
                advancedOrganizeImportsSupport = true,
                generateConstructorsPromptSupport = true,
                generateDelegateMethodsPromptSupport = true,
                moveRefactoringSupport = true,
                inferSelectionSupport = {"extractMethod", "extractVariable", "extractConstant"}
            }
        },
        settings = {
            java = {
                signatureHelp = {enabled = true},
                contentProvider = {preferred = 'fernflower'},
                format = {insertSpaces = true, tabSize = 4},
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

    local system_name
    if vim.fn.has("mac") == 1 then
        system_name = "macOS"
    elseif vim.fn.has("unix") == 1 then
        system_name = "Linux"
    elseif vim.fn.has('win32') == 1 then
        system_name = "Windows"
    else
        print("Unsupported system for sumneko")
    end

    -- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
    local sumneko_root_path = vim.fn.expand('~/.local/src/lua-language-server')
    local sumneko_binary = sumneko_root_path .. "/bin/" .. system_name .. "/lua-language-server"

    local luadev = require("lua-dev").setup({
        -- add any options here, or leave empty to use the default settings
        lspconfig = {
            cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
            on_attach = on_attach,
            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                        -- Setup your lua path
                        path = vim.split(package.path, ';')
                    },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = {'vim', 'use'}
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = {
                            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
                        }
                    }
                }
            },
            capabilities = capabilities
        }
    })
    lspconfig.sumneko_lua.setup(luadev)

    lspconfig.efm.setup {
        on_attach = on_attach,
        init_options = {documentFormatting = true},
        filetypes = {"lua"},
        settings = {
            rootMarkers = {".git/"},
            languages = {
                lua = {
                    {
                        formatCommand = "lua-format -i --column-limit=120", -- --no-keep-simple-function-one-line --no-break-after-operator --column-limit=150 --break-after-table-lb",
                        formatStdin = true
                    }
                }
            }
        }
    }
end

function M.setup_jdtls()
    local home = os.getenv('HOME')

    local jar_patterns = {
        home .. '/.local/src/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
        home .. '/.local/src/vscode-java-test/server/*.jar'
        -- home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.plugin/target/*.jar',
        -- home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.runner/target/*.jar',
        -- home .. '/.local/src/vscode-java-test/java-extension/com.microsoft.java.test.runner/lib/*.jar'
    }

    local bundles = {}
    for _, jar_pattern in ipairs(jar_patterns) do
        for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
            if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') then
                table.insert(bundles, bundle)
            end
        end
    end

    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
    local config = {
        cmd = {'jdtls.sh', home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")},
        flags = {allow_incremental_sync = true, server_side_fuzzy_completion = true},
        capabilities = {
            workspace = {configuration = true},
            textDocument = {completion = {completionItem = {snippetSupport = true}}}
        },
        on_attach = on_attach,
        init_options = {bundles = bundles, extendedClientCapabilities = extendedClientCapabilities},
        handlers = {
            ['textDocument/definition'] = function(_, method, params, client_id, bufnr, config)
                dump(method, params, client_id, bufnr, config)
                vim.lsp.handlers['textDocument/definition'](nil, method, params, client_id, bufnr, config)
            end
        },
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

    local finders = require 'telescope.finders'
    local sorters = require 'telescope.sorters'
    local actions = require 'telescope.actions'
    local pickers = require 'telescope.pickers'
    require('jdtls.ui').pick_one_async = function(items, prompt, label_fn, cb)
        local opts = {}
        pickers.new(opts, {
            prompt_title = prompt,
            finder = finders.new_table {
                results = items,
                entry_maker = function(entry)
                    return {value = entry, display = label_fn(entry), ordinal = label_fn(entry)}
                end
            },
            sorter = sorters.get_generic_fuzzy_sorter(),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = actions.get_selected_entry(prompt_bufnr)
                    actions.close(prompt_bufnr)
                    cb(selection.value)
                end)
                return true
            end
        }):find()
    end

    jdtls.start_or_attach(config)
end

return M
