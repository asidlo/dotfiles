local null_ls_status_ok, null_ls = pcall(require, 'null-ls')
if not null_ls_status_ok then
    return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

local handlers_ok, handlers = pcall(require, 'user.lsp.handlers')
if not handlers_ok then
    return
end

null_ls.setup({
    debug = true,
    on_attach = handlers.on_attach,
    sources = {
        formatting.black.with({ extra_args = { '--fast' } }),

        -- Lua
        formatting.stylua.with({
            extra_args = {
                '--indent-width',
                '4',
                '--quote-style',
                'AutoPreferSingle',
                '--indent-type',
                'Spaces',
            },
        }),
        diagnostics.luacheck.with({
            extra_args = {
                '--globals',
                'lvim',
                '--globals',
                'vim',
                '--formatter',
                'plain',
                '--codes',
                '--ranges',
                '--filename',
                '$FILENAME',
                '-',
            },
        }),

        -- Shell
        formatting.shellharden.with({ filetypes = { 'bash', 'sh' } }),
        diagnostics.shellcheck.with({ filetypes = { 'bash', 'sh' } }),

        -- Markdown
        formatting.prettierd,
        diagnostics.markdownlint.with({ extra_args = { '-c', os.getenv('HOME') .. '/.markdownlint.json' } }),

        -- Text
        diagnostics.vale,
    },
})
