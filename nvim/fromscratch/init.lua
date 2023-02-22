vim.defer_fn(function()
  pcall(require, "impatient")
end, 0)

require('user.colorscheme')

local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    print "Cloning packer..."
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })

    local plugins = require "user.plugins"
    plugins.init()
    plugins.startup()
    vim.cmd("PackerSync")

    -- install binaries from mason.nvim & tsparsers
    vim.api.nvim_create_autocmd("User", {
        pattern = "PackerComplete",
        callback = function()
            vim.cmd("bw | silent! MasonInstallAll") -- close packer window
            require("packer").loader "nvim-treesitter"
        end,
    })
end

require('user.options')
require('user.util')
require('user.keymaps')
require('user.autocommands')

-- local plugins = require('user.plugins')
-- plugins.init()
-- plugins.startup()
--
-- local running_headless = #vim.api.nvim_list_uis() == 0
-- if running_headless then
--     return
-- end

-- require('user.lsp')
