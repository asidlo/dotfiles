-- Yank till end of line
vim.api.nvim_set_keymap('n', 'Y', 'y$', {noremap = true, silent = true})

-- Center search hit on next
vim.api.nvim_set_keymap('n', 'n', 'nzzzv', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'N', 'Nzzzv', {noremap = true, silent = true})

-- Move cusor by display lines when wrapping
vim.api.nvim_set_keymap('n', '<Up>', 'gk', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Down>', 'gj', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'j', 'gj', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'k', 'gk', {noremap = true, silent = true})

-- Change pwd to current directory
vim.api.nvim_set_keymap('n', '<Leader>cd', '<Cmd>cd %:p:h<CR>', {noremap = true, silent = true})
