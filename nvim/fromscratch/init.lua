vim.defer_fn(function()
  pcall(require, "impatient")
end, 0)

require('user.colorscheme')

local fn = vim.fn
local ensure_packer = function()
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

require('user.options')
require('user.util')
require('user.keymaps')
require('user.autocommands')

local packer_bootstrap = ensure_packer()

local plugins = require "user.plugins"
plugins.init()
plugins.startup()

if packer_bootstrap then
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
