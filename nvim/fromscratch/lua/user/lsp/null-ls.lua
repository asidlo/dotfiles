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

-- Check for unix home and if not present then use windows equivalent
local home = os.getenv('HOME')
if not home then
    home = os.getenv('HOMEPATH')
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
        -- JSON, graphql, yaml, and javascript varients can also be formatted with prettier,
        -- but they have their own dedicated LSPs
        formatting.prettierd.with({ filetypes = { 'markdown', 'html', 'css', 'scss', 'less' } }),
        diagnostics.markdownlint.with({ extra_args = { '-c', home .. '/.markdownlint.json' } }),

        -- Text
        -- diagnostics.vale,
    },
})
