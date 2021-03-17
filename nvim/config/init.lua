local install_path = vim.fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.api.nvim_command('!git clone https://github.com/wbthomason/packer.nvim '..install_path)
  vim.cmd 'packadd packer.nvim'
  vim.cmd 'PackerInstall'
else
  vim.cmd 'packadd packer.nvim'
end

require'util'
require'config.augroups'
require'config.options'
require'config.mappings'
require'config.packages'
