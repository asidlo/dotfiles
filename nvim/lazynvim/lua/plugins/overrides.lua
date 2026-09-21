-- Upstream clangd publishes no Linux arm64 binary, so mason can never install it
-- on this architecture ("The current platform is unsupported").
local uname = vim.loop.os_uname()
local is_linux_arm64 = uname.sysname == "Linux" and (uname.machine == "aarch64" or uname.machine == "arm64")

-- mason package -> the executable scripts/nvim-tools.sh installs globally.
local npm_fallbacks = {
  ["prettier"] = "prettier",
}

local spec = {
  { "folke/edgy.nvim", opts = { animate = { enabled = false } } },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- sh/bash diagnostics come from bashls (extras.util.dot), which runs
        -- shellcheck itself. markdownlint-cli2 is repeated here because this
        -- table replaces, rather than extends, the one from extras.lang.markdown.
        gitcommit = { "gitlint" },
        markdown = { "markdownlint-cli2" },
        ["*"] = { "codespell" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "gitlint",
        "codespell",
        "bicep-lsp",
        "lemminx",
        "powershell-editor-services",
      })
      -- mason pins an exact version for each npm package and fails forever when
      -- the configured registry does not carry it. scripts/nvim-tools.sh
      -- installs these globally instead, so drop any that are already on PATH.
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return not (npm_fallbacks[pkg] and vim.fn.executable(npm_fallbacks[pkg]) == 1)
      end, opts.ensure_installed)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Installed globally by scripts/nvim-tools.sh; see npm_fallbacks above.
        bashls = { mason = vim.fn.executable("bash-language-server") == 0 },
        -- Grammar checking for prose. Restricted to prose filetypes (it defaults
        -- to 29, including source files) and with the dictionary-based rules off,
        -- since technical vocabulary makes them almost entirely false positives.
        -- codespell covers real typos via nvim-lint without a dictionary to maintain.
        harper_ls = {
          filetypes = { "markdown", "text", "gitcommit" },
          settings = {
            ["harper-ls"] = {
              linters = {
                SpellCheck = false,
                OrthographicConsistency = false,
                DisjointPrefixes = false,
                UseTitleCase = false,
                SentenceCapitalization = false,
                ExpandConfiguration = false,
                SplitWords = false,
              },
            },
          },
        },
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

-- clangd has no Linux arm64 release; use the system binary from PATH
-- (installed by scripts/clangd.sh) rather than letting mason fail on every startup.
local clangd_from_path = {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      clangd = { mason = false },
    },
  },
}

if is_linux_arm64 then
  table.insert(spec, clangd_from_path)
end

if vim.loop.os_uname().sysname == "Windows_NT" then
  table.insert(spec, disable_omnisharp)
end

return spec
