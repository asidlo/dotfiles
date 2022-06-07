local present, impatient = pcall(require, "impatient")

if present then
    impatient.enable_profile()
end

local autocmd = vim.api.nvim_create_autocmd

-- Disable statusline in dashboard
autocmd("FileType", {
    pattern = "alpha",
    callback = function()
        vim.opt.laststatus = 0
    end,
})

autocmd("BufUnload", {
    buffer = 0,
    callback = function()
        vim.opt.laststatus = 3
    end,
})

-- Just have options, keymaps, and plugins
-- keep autocommands and utils here and others sourced in plugins
-- or keep separate also autocommands, utils
require("user.options")
require("user.util")
require("user.keymaps")
require("user.plugins")
require("user.colorscheme")
require("user.cmp")
require("user.lsp")
require("user.telescope")
require("user.treesitter")
require("user.autopairs")
require("user.comment")
require("user.gitsigns")
require("user.nvim-tree")
require("user.bufferline")
require("user.lualine")
require("user.toggleterm")
require("user.project")
require("user.indentline")
require("user.alpha")
require("user.whichkey")
require("user.autocommands")
