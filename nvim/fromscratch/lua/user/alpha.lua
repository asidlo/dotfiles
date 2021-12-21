local status_ok, alpha = pcall(require, 'alpha')
if not status_ok then
    return
end

local dashboard = require('alpha.themes.dashboard')
dashboard.section.header.val = {
    '                                                     ',
    '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ',
    '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ',
    '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ',
    '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ',
    '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ',
    '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ',
    '                                                     ',
}
dashboard.section.buttons.val = {
    dashboard.button('f', '  Find file', ':Telescope find_files <CR>'),
    dashboard.button('e', '  New file', ':ene <BAR> startinsert <CR>'),
    dashboard.button('p', '  Find project', ':Telescope projects <CR>'),
    dashboard.button('r', '  Recently used files', ':Telescope oldfiles <CR>'),
    dashboard.button('t', '  Find text', ':Telescope live_grep <CR>'),
    dashboard.button('c', '  Configuration', ':e ~/.config/nvim/init.lua <CR>'),
    dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
}

-- local function footer()
--     local total_plugins = #vim.fn.globpath(vim.fn.stdpath('data') .. '/site/pack/packer/start', '*', 0, 1)
--     local datetime = os.date('%d-%m-%Y %H:%M:%S')
--     return string.format('Loaded %d plugins   on  %s', total_plugins, datetime)
-- end

-- local fortune = require('alpha.fortune')
-- dashboard.section.footer.val = fortune
dashboard.section.footer.val = os.date(' %d-%m-%Y   %H:%M:%S')

dashboard.section.header.opts.hl = 'Include'
dashboard.section.footer.opts.hl = "Type"
dashboard.section.buttons.opts.hl = "Keyword"
-- dashboard.section.footer.opts.hl = 'Keyword'

dashboard.opts.opts.noautocmd = true
-- vim.cmd([[autocmd User AlphaReady echo 'ready']])
alpha.setup(dashboard.opts)
