-- local actions = require('telescope.actions')

-- require('telescope').setup {
--	   defaults = {
--		   mappings = {
--			   i = {
--				   ["<esc>"] = actions.close
--			   }
--		   }
--	   }
-- }

set_keymap('n', '<Leader>F', '<Cmd>Telescope find_files<CR>')
set_keymap('n', '<Leader>f', '<Cmd>Telescope git_files<CR>')
set_keymap('n', '<Leader>b', '<Cmd>Telescope buffers<CR>')
set_keymap('n', '<Leader>e', '<Cmd>Telescope oldfiles<CR>')
set_keymap('n', '<Leader>x', '<Cmd>Telescope keymaps<CR>')
set_keymap('n', '<Leader>X', '<Cmd>Telescope commands<CR>')
