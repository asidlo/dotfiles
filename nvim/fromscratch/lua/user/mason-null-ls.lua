local status_ok, mason_null_ls = pcall(require, 'mason-null-ls')
if not status_ok then
    return
end

local status_ok, null_ls = pcall(require, 'null-ls')
if not status_ok then
    return
end

local home = os.getenv('HOME')
if not home then
    home = os.getenv('HOMEPATH')
end

mason_null_ls.setup({ automatic_setup = true })
mason_null_ls.setup_handlers {
    function(source_name, methods)
        require("mason-null-ls.automatic_setup")(source_name, methods)
    end,
    markdownlint = function(_, _)
        null_ls.register(null_ls.builtins.diagnostics.markdownlint.with({
            extra_args = { '-c', home .. '/.markdownlint.json' }
        }))
    end,
}
