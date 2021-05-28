set_keymap('n', '<M-n>', '<Cmd>NvimTreeToggle<CR>')
set_keymap('n', '<M-o>', '<Cmd>NvimTreeFindFile<CR>')
vim.g.nvim_tree_width = 40
vim.g.nvim_tree_width_allow_resize = 1
vim.g.nvim_tree_window_picker_exclude = {
    filetype = {
        'packer',
        'qf'
    },
    buftype = {
        'terminal'
    }
}
