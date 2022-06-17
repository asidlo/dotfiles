local M = {}

local push_error = function(error)
    if not M.err then
        M.err = {}
    end
    table.insert(M.err, error)
end

M.separator = ''

M.disabled_filetypes = {
    'alpha', 'NvimTree', 'packer', 'toggleterm', 'help',
    'Trouble', 'Outline', 'TelescopePrompt', '', 'git', 'gitmessengerpopup'
}

M.setup = function()
    local colors_ok, colors = pcall(require, 'tokyonight.colors')
    if not colors_ok then
        vim.notify(string.format('user.winbar.setup() -> Missing tokyonight.colors', vim.log.levels.WARN))
    else
        M.colors = colors.setup()
        vim.api.nvim_set_hl(0, 'WinBar', { bg = M.colors.bg, fg = M.colors.comment })
    end

    local navic_ok, navic = pcall(require, 'nvim-navic')
    if not navic_ok then
        vim.notify(string.format('user.winbar.setup() -> Missing nvim-navic', vim.log.levels.WARN))
        return
    end

    M.navic = navic

    M.navic.setup({
        separator = ' ' .. M.separator .. ' '
    })
end

-- See :h statusline for %v values
M.eval = function()
    if vim.tbl_contains(M.disabled_filetypes, vim.bo.filetype) then
        vim.opt_local.winbar = nil
        return
    end

    vim.opt_local.winbar = "%{%v:lua.require('user.winbar').eval()%}"

    local file_path = vim.api.nvim_eval_statusline('%f', {}).str
    -- local modified = vim.api.nvim_eval_statusline('%M', {}).str

    file_path = file_path:gsub('/', string.format(' %s ', M.separator))

    if not M.navic or not M.navic.is_available() then
        return string.format('     %s', file_path)
    end

    if M.navic.get_location() == "" then
        return string.format('     %s', file_path)
    end

    return string.format('     %s %s %s', file_path, M.separator, M.navic.get_location())

    -- return '%#WinBarPath#' .. file_path .. '%*' .. '%#WinBarModified#' .. modified .. '%*'
end

return M
