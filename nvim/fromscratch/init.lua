-- In order to have a smooth experience, make sure you run nvim in headless mode the first time
-- via `nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'`.  This will
-- install all of the plugins and cache them so the next execution of nvim will start quick.
-- TODO (AS): Figure out whichkey+Ferret conflict during headless install

local present, impatient = pcall(require, 'impatient')

if present then
    impatient.enable_profile()
end

local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd('packadd packer.nvim')
end

local plugins = require('user.plugins')
plugins.init()
plugins.startup()

if vim.tbl_isempty(plugins.installed_plugins()) then
    return
end

require('user.options')
require('user.util')
require('user.keymaps')

require('user.autocommands')
require('user.lsp')

local scheme = require('user.colorscheme')
if scheme.err ~= nil then
    local msg = string.format('Unable to load colorscheme -> %s', vim.inspect(scheme.err))
    vim.notify(msg, vim.log.levels.WARN)
end
