-- Until they release the `vim.lsp.util.formatexpr()`
-- https://github.com/neovim/neovim/issues/12528
-- https://github.com/neovim/neovim/pull/12547
-- https://github.com/neovim/neovim/pull/13138
--
--- Implements an LSP `formatexpr`-compatible
-- @param start_line 1-indexed line, defaults to |v:lnum|
-- @param end_line 1-indexed line, calculated based on {start_line} and |v:count|
-- @param timeout_ms optional, defaults to 500ms
_G.lsp_formatexpr = function(start_line, end_line, timeout_ms)
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
        vim.lsp.buf.range_formatting({}, { start_line, 0 }, { end_line, end_char })
    end

    -- do not run builtin formatter after lsp format
    return 0
end

local M = {}

-- TODO: backfill this to template
M.setup = function()
    local signs = {
        { name = 'DiagnosticSignError', text = '' },
        { name = 'DiagnosticSignWarn', text = '' },
        { name = 'DiagnosticSignHint', text = '' },
        { name = 'DiagnosticSignInfo', text = '' },
    }

    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = '' })
    end

    local config = {
        -- disable virtual text
        virtual_text = false,
        -- show signs
        signs = {
            active = signs,
        },
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
            focusable = false,
            style = 'minimal',
            border = 'rounded',
            source = 'always',
            header = '',
            prefix = '',
        },
    }

    vim.diagnostic.config(config)

    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = 'rounded',
    })

    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = 'rounded',
    })
end

local function lsp_highlight_document(client)
    local capabilities = nil
    local version = vim.version()
    if version.major > 0 or version.minor >= 8 then
        capabilities = client.server_capabilities
    else
        capabilities = client.resolved_capabilities
    end

    -- Set autocommands conditional on server_capabilities
    if capabilities.document_highlight then
        vim.api.nvim_exec(
            [[
                  augroup lsp_document_highlight
                    autocmd! * <buffer>
                    autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                    autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
                  augroup END
            ]],
            false
        )
    end
end

local function lsp_keymaps(bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-]>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua require("user.lsp.handlers").show_documentation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 's', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gl', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting()' ]])
    vim.api.nvim_buf_set_keymap(
        bufnr,
        'n',
        '<leader>lD',
        '<cmd>lua require("user.lsp.handlers").toggle_diagnostics()<CR>',
        opts
    )
end

local function lsp_code_lens_refresh(client)
    local capabilities = nil
    local version = vim.version()
    if version.major > 0 or version.minor >= 8 then
        capabilities = client.server_capabilities
    else
        capabilities = client.resolved_capabilities
    end

    if capabilities.code_lens then
        vim.api.nvim_exec(
            [[
                  augroup lsp_code_lens_refresh
                    autocmd! * <buffer>
                    autocmd InsertLeave <buffer> lua vim.lsp.codelens.refresh()
                    autocmd InsertLeave <buffer> lua vim.lsp.codelens.display()
                  augroup END
            ]],
            false
        )
    end
end

M.on_attach = function(client, bufnr)
    local capabilities = nil
    local version = vim.version()
    if version.major > 0 or version.minor >= 8 then
        capabilities = client.server_capabilities
    else
        capabilities = client.resolved_capabilities
    end

    if capabilities.document_range_formatting then
        vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end

    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    lsp_keymaps(bufnr)

    if client.name ~= 'powershell_es' then
        lsp_highlight_document(client)
    end
    lsp_code_lens_refresh(client)

    local status_ok, lspsig = pcall(require, 'lsp_signature')
    if not status_ok then
        return
    end
    lspsig.on_attach()

    if client.name ~= 'null-ls' then
        local navic_ok, navic = pcall(require, 'nvim-navic')
        if not navic_ok then
            return
        end
        navic.attach(client, bufnr)
    end
end

local status_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if not status_ok then
    return
end

M.capabilities = cmp_nvim_lsp.update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- https://github.com/neovim/neovim/issues/14825
vim.g.diagnostics_visible = true

M.toggle_diagnostics = function()
    if vim.g.diagnostics_visible then
        vim.g.diagnostics_visible = false
        vim.diagnostic.hide()
        print('Diagnostics are hidden')
    else
        vim.g.diagnostics_visible = true
        vim.diagnostic.show()
        vim.cmd('e ' .. vim.fn.expand('%'))
        print('Diagnostics are visible')
    end
end

M.show_documentation = function()
    local filetype = vim.bo.filetype
    if vim.tbl_contains({ 'vim', 'help' }, filetype) then
        vim.cmd('h ' .. vim.fn.expand('<cword>'))
    elseif vim.tbl_contains({ 'man' }, filetype) then
        vim.cmd('Man ' .. vim.fn.expand('<cword>'))
    elseif vim.fn.expand('%:t') == 'Cargo.toml' then
        require('crates').show_popup()
    else
        vim.lsp.buf.hover()
    end
end

return M
