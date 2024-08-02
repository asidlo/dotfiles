local spec = {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        gitcommit = { "gitlint" },
        text = { "vale" },
        markdown = { "vale", "markdownlint" },
        ["*"] = { "codespell" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "markdownlint", "cbfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        sh = { "shfmt" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "gitlint",
        "shellcheck",
        "codespell",
        "vale",
        "bicep-lsp",
        "cbfmt",
        "lemminx",
        "beautysh",
        "powershell-editor-services",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
              OrganizeImports = true,
            },
            MsBuild = {
              LoadProjectsOnDemand = true,
            },
            RoslnRoslynExtensionsOptions = {
              -- Enables support for roslyn analyzers, code fixes and rulesets.
              EnableAnalyzersSupport = true,
              EnableImportCompletion = true,
              AnalyzeOpenDocumentsOnly = true,
            },
          },
        },
        -- https://github.com/neovim/nvim-lspconfig/issues/2810
        powershell_es = {
          init_options = { enableProfileLoading = false },
          settings = {
            powershell = {
              codeFormatting = {
                openBraceOnSameLine = false,
                whitespaceInsideBrace = true,
              },
            },
          },
        },
      },
    },
  },
}

local disable_cursor_animate = {
  "echasnovski/mini.animate",
  opts = function(_, opts)
    opts.cursor = { enable = false }
  end,
}

local disable_edgy_animate = {
  "folke/edgy.nvim",
  opts = {
    animate = {
      enabled = false,
    },
  },
}

local disable_omnisharp = {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      omnisharp = {
        enabled = false,
      },
    },
  },
}

if not vim.loop.os_uname().sysname == "Windows_NT" then
  -- animate plugin is already disabled in windows in lazy.lua
  table.insert(spec, disable_cursor_animate)
else
  table.insert(spec, disable_edgy_animate)
  table.insert(spec, disable_omnisharp)
end

return spec
