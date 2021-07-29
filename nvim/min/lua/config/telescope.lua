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
local is_unix = function() return vim.fn.has('unix') == 1 and vim.fn.has('macunix') == 0 end

local fd_cmd = function()
    if is_unix() then return 'fdfind' end
    return 'fd'
end

require('telescope').setup {
    pickers = {
        find_files = {
            -- TODO: AS - remove once we can pass a list of excluded members and uncomment no_ignore
            find_command = {
                fd_cmd(), '-I', '--follow', '--exclude', '.git', '--exclude', 'node_modules', '--exclude', '*.class'
            },
            -- no_ignore = true,
            hidden = true,
            follow = true
        }
    }
}

set_keymap('n', '<Leader>F', '<Cmd>Telescope find_files<CR>')
set_keymap('n', '<Leader>f', '<Cmd>Telescope git_files<CR>')
set_keymap('n', '<Leader>b', '<Cmd>Telescope buffers<CR>')
set_keymap('n', '<Leader>e', '<Cmd>Telescope oldfiles<CR>')
set_keymap('n', '<Leader>x', '<Cmd>Telescope keymaps<CR>')
set_keymap('n', '<Leader>X', '<Cmd>Telescope commands<CR>')
