set_keymap('n', '<Leader>n', '<Cmd>NvimTreeToggle<CR>')
set_keymap('n', '<Leader>N', '<Cmd>NvimTreeFindFile<CR>')
vim.g.nvim_tree_width = 40
vim.g.nvim_tree_auto_resize = 0
vim.g.nvim_tree_window_picker_exclude = {
	filetype = {
		'packer',
		'qf'
	},
	buftype = {
		'terminal'
	}
}
