set_keymap('n', '<Leader>n', '<Cmd>NvimTreeToggle<CR>')
set_keymap('n', '<Leader>N', '<Cmd>NvimTreeFindFile<CR>')
vim.g.nvim_tree_width = 40
vim.g.nvim_tree_auto_resize = 0
vim.g.nvim_tree_group_empty = 1
vim.g.nvim_tree_gitignore = 1
vim.g.nvim_tree_ignore = {'.git', 'node_modules', '.cache', '.DS_Store'}
vim.g.nvim_tree_highlight_opened_files = 1
vim.g.nvim_tree_window_picker_exclude = {filetype = {'packer', 'qf'}, buftype = {'terminal'}}
