local present, null_ls = pcall(require, "null-ls")

if not present then
  return
end

local b = null_ls.builtins

local home = os.getenv('HOME')
if not home then
    home = os.getenv('HOMEPATH')
end

local sources = {

  b.formatting.prettierd.with { filetypes = { "html", "markdown", "css" } },
  b.diagnostics.markdownlint.with { extra_args = { '-c', home .. '/.markdownlint.json' } },
  b.formatting.stylua.with({
         extra_args = {
          '--indent-width',
          '4',
          '--quote-style',
          'AutoPreferSingle',
          '--indent-type',
          'Spaces',
      },
  });

b.diagnostics.luacheck.with({
            extra_args = {
                '--globals',
                'lvim',
                '--globals',
                'vim',
                '--formatter',
                'plain',
                '--codes',
                '--ranges',
                '--no-max-line-length',
                '--filename',
                '$FILENAME',
                '-',
            },
        }),
  b.formatting.shellharden.with({ filetypes = { 'bash', 'sh' } }),
  b.diagnostics.shellcheck.with({ filetypes = { 'bash', 'sh' }, diagnostics_format = "#{m} [#{c}]" }),
}

null_ls.setup {
  debug = true,
  sources = sources,
}
