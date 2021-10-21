vim.cmd('setlocal expandtab tabstop=4 shiftwidth=4')
vim.cmd('setlocal foldlevel=2')
vim.cmd('setlocal colorcolumn=120')

vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<Leader>la',
    '<Cmd>lua require("jdtls").code_action()<cr>',
    { noremap = true, silent = true }
)
vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<M-CR>',
    '<Cmd>lua require("jdtls").code_action()<cr>',
    { noremap = true, silent = true }
)
vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<M-o>',
    '<Cmd>lua require("jdtls").organize_imports()<cr>',
    { noremap = true, silent = true }
)

local lvim_lsp = require('lvim.lsp')
local jdtls = require('jdtls')
local home = os.getenv('HOME')

-- https://github.com/neovim/neovim/issues/12970
vim.lsp.util.apply_text_document_edit = function(text_document_edit, _)
    local text_document = text_document_edit.textDocument
    local bufnr = vim.uri_to_bufnr(text_document.uri)

    vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr)
end

local jar_patterns = {
    home .. '/.local/src/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
    home .. '/.local/src/vscode-java-test/server/*.jar',
}

local bundles = {}
for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
        if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') and bundle ~= '' then
            table.insert(bundles, bundle)
        end
    end
end

local extra_capabilities = {
    workspace = { configuration = true },
    textDocument = {
        codeAction = {
            dataSupport = true,
            resolveSupport = { properties = { 'edit' } },
            codeActionLiteralSupport = {
                codeActionKind = {
                    valueSet = {
                        'source.generate.toString',
                        'source.generate.hashCodeEquals',
                        'source.organizeImports',
                    },
                },
            },
        },
        completion = { completionItem = { snippetSupport = true } },
    },
}

local jdtls_capabilities = jdtls.extendedClientCapabilities
jdtls_capabilities.resolveAdditionalTextEditsSupport = true

local config = {
    cmd = {
        -- TODO (AS): Move script here and use eclipse jdtls installed from lsp-installer
        'jdtls.sh',
        os.getenv('HOME') .. '/.local/share/eclipse/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t'),
    },
    on_attach = function(client, bufnr)
        lvim_lsp.common_on_attach(client, bufnr)
        -- Check if jars exists for dap and tests
        if next(bundles) then
            -- jdtls.setup_dap({ hotcodereplace = 'auto' })
            jdtls.setup_dap({ hotcodereplace = 'auto' })
            require('jdtls.dap').setup_dap_main_class_configs()
            require('jdtls.setup').add_commands()
        else
            print('No debug/test jars passed into init_options...not loading jdtls.dap')
        end
    end,
    on_init = lvim_lsp.common_on_init,
    capabilities = vim.tbl_deep_extend('keep', lvim_lsp.common_capabilities(), extra_capabilities),
    flags = { allow_incremental_sync = true, server_side_fuzzy_completion = true },
    init_options = {
        bundles = bundles,
        extendedClientCapabilities = jdtls_capabilities,
    },
    settings = {
        java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
            format = {
                settings = {
                    url = 'file://' .. os.getenv('HOME') .. '/.eclipse-java-style.xml',
                    profile = 'nexidia-rtig',
                },
            },
            codeGeneration = {
                toString = { template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}' },
            },
            configuration = {
                runtimes = {
                    {
                        name = 'JavaSE-11',
                        path = home .. '/.sdkman/candidates/java/11.0.11-zulu/',
                        default = true,
                    },
                    { name = 'JavaSE-1.8', path = home .. '/.sdkman/candidates/java/8.0.292-zulu' },
                },
            },
        },
    },
}

-- TODO (AS): Look into how to use lsp-settings to read json settings for lsp
config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
end

local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local themes = require('telescope.themes')

-- TODO (AS): Hook jdtls functions into lvim.lsp mappings
require('jdtls.ui').pick_one_async = function(items, prompt, label_fn, cb)
    local opts = themes.get_dropdown({
        winblend = 15,
        layout_config = {
            prompt_position = 'top',
            width = 80,
            height = 12,
        },
        borderchars = {
            prompt = { '─', '│', ' ', '│', '╭', '╮', '│', '│' },
            results = { '─', '│', '─', '│', '├', '┤', '╯', '╰' },
            preview = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
        },
        border = {},
        previewer = false,
        shorten_path = false,
    })
    pickers.new(opts, {
        prompt_title = prompt,
        finder = finders.new_table({
            results = items,
            entry_maker = function(entry)
                return { value = entry, display = label_fn(entry), ordinal = label_fn(entry) }
            end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = require('telescope.actions.state').get_selected_entry(prompt_bufnr)
                actions.close(prompt_bufnr)
                cb(selection.value)
            end)
            return true
        end,
    }):find()
end

jdtls.start_or_attach(config)
