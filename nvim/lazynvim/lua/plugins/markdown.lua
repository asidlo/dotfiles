return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "markdownlint")
      table.insert(opts.ensure_installed, "markdown-toc")
      table.insert(opts.ensure_installed, "cbfmt")
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      table.insert(opts.sources, nls.builtins.formatting.markdownlint)
      table.insert(opts.sources, nls.builtins.formatting.cbfmt)
      table.insert(opts.sources, nls.builtins.formatting.markdown_toc)
      nls.register(nls.builtins.diagnostics.markdownlint.with({
        extra_args = { "--config", vim.fn.expand("~/.markdownlint.json") },
      }))
    end,
  },
}
