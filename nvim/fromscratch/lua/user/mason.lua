local present, mason = pcall(require, "mason")

if not present then
    return
end

local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. vim.fn.stdpath "data" .. "/mason/bin"

-- vim.api.nvim_create_augroup("_mason", { clear = true })
-- vim.api.nvim_create_autocmd("Filetype", {
--   pattern = "mason",
--   callback = function()
--     require("base46").load_highlight "mason"
--   end,
--   group = "_mason",
-- })

local options = {
    ensure_installed = {
        "lua-language-server",
        "json-lsp",
        "bash-language-server",
        "omnisharp",
        "pyright",
        "rust-analyzer",
        "gopls",
        "docker-compose-language-service",
        "bicep-lsp",
        "clangd",
        "cmake-language-server",
        "marksman",
        "prosemd-lsp",
        "markdownlint",
        "prettierd",
        "shfmt",
        "typescript-language-server",
        "eslint_d"
    },
    PATH = "skip",
    ui = {
        border = "rounded",
        icons = {
            package_pending = " ",
            package_installed = " ",
            package_uninstalled = " ﮊ",
        },

        keymaps = {
            toggle_server_expand = "<CR>",
            install_server = "i",
            update_server = "u",
            check_server_version = "c",
            update_all_servers = "U",
            check_outdated_servers = "C",
            uninstall_server = "X",
            cancel_installation = "<C-c>",
        },
    },
    max_concurrent_installers = 10,
}

vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("MasonInstall " .. table.concat(options.ensure_installed, " "))
end, {})

mason.setup(options)
