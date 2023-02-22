-- In order to have a smooth experience, make sure you run nvim in headless mode the first time
-- via `nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'`.  This will
-- install all of the plugins and cache them so the next execution of nvim will start quick.
local present, impatient = pcall(require, 'impatient')

if present then
    impatient.enable_profile()
end

local ok, notify = pcall(require, 'user.notify')
if ok then
    notify.setup()
end

require('user.colorscheme')

local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd('packadd packer.nvim')

    local plugins = require "user.plugins"
    plugins.init()
    plugins.startup()
    vim.cmd "PackerSync"

    -- install binaries from mason.nvim & tsparsers
    vim.api.nvim_create_autocmd("User", {
      pattern = "PackerComplete",
      callback = function()
        vim.cmd "bw | silent! MasonInstallAll" -- close packer window
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

