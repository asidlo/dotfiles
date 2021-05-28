-- https://draculatheme.com/contribute
vim.api.nvim_command('hi BufferTabpageFill guibg=#282a36')
vim.api.nvim_command('hi BufferInactive guibg=#282a36 guifg=#6272a4')
vim.api.nvim_command('hi BufferInactiveIndex guibg=#282a36')
vim.api.nvim_command('hi BufferInactiveIndex guibg=#282a36')
vim.api.nvim_command('hi BufferInactiveMod guibg=#282a36')
vim.api.nvim_command('hi BufferInactiveSign guibg=#282a36')
vim.api.nvim_command('hi BufferInactiveTarget guibg=#282a36')

local barbar_tree ={}
barbar_tree.open = function ()
   require'bufferline.state'.set_offset(31, 'FileTree')
   require'nvim-tree'.find_file(true)
end
barbar_tree.close = function ()
   require'bufferline.state'.set_offset(0)
   require'nvim-tree'.close()
end

return barbar_tree
