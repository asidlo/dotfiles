local present, impatient = pcall(require, 'impatient')

if present then
    impatient.enable_profile()
end

require('user.options')
require('user.util')
require('user.autocommands')
require('user.keymaps')

local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#1e222a' })

if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd('packadd packer.nvim')

    -- if plugin install dir is missing, then remove the complied file if it exists
    if fn.empty(fn.glob('~/.config/nvim/plugin/packer_compiled.lua')) == 0 then
        fn.system({ 'rm', '~/.config/nvim/plugin/packer_compiled.lua' })
    end

    local plugins = require('user.plugins')

    if #vim.api.nvim_list_uis() == 0 then
        plugins.init({ display = nil })
        plugins.startup()
    else
        plugins.init()
        require('packer').on_complete = vim.schedule_wrap(function()
            vim.cmd('source $MYVIMRC')
        end)
        plugins.startup()
        vim.cmd('PackerSync')
    end
else
    local plugins = require('user.plugins')
    plugins.init()
    plugins.startup()

    -- Plugin specific settings
    require('user.colorscheme')
    require('user.cmp')
    require('user.lsp')
    require('user.telescope')
    require('user.treesitter')
    require('user.comment')
    require('user.gitsigns')
    require('user.nvim-tree')
    require('user.bufferline')
    require('user.lualine')
    require('user.toggleterm')
    require('user.project')
    require('user.indentline')
    require('user.alpha')
    require('user.whichkey')
end
