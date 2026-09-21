-- Upstream clangd and cbfmt publish no Linux arm64 binaries, so mason can never
-- install them on this architecture ("The current platform is unsupported").
local uname = vim.loop.os_uname()
local is_linux_arm64 = uname.sysname == "Linux" and (uname.machine == "aarch64" or uname.machine == "arm64")

local spec = {
  { "folke/edgy.nvim", opts = { animate = { enabled = false } } },
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
        -- On arm64, cbfmt comes from
        -- `cargo install --git https://github.com/lukas-reineke/cbfmt --locked`
        markdown = { "markdownlint", "cbfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        sh = { "shfmt" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "gitlint",
        "shellcheck",
        "codespell",
        "vale",
        "bicep-lsp",
        "lemminx",
        "beautysh",
        "powershell-editor-services",
      })
      if not is_linux_arm64 then
        table.insert(opts.ensure_installed, "cbfmt")
      end
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
-- (`sudo apt install clangd`) rather than letting mason fail on every startup.
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
