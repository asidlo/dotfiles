local M = {}

local colors_ok, colors = pcall(require, 'tokyonight.colors')
if not colors_ok then
    return
end
colors = colors.setup()

-- vim.api.nvim_set_hl(0, 'WinBarPath', {bg = colors.black, fg = colors.fg_dark})
-- vim.api.nvim_set_hl(0, 'WinBarModified', {bg = colors.bg_dark, fg = colors.fg_dark})
vim.api.nvim_set_hl(0, 'WinBar', { bg = colors.bg_dark, fg = colors.comment })

local separator = ''

local disabled_filetypes = { 'alpha', 'NvimTree' }

-- See :h statusline for %v values
M.eval = function()
    if vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
        vim.opt_local.winbar = nil
        return
    end

    local file_path = vim.api.nvim_eval_statusline('%f', {}).str
    -- local modified = vim.api.nvim_eval_statusline('%M', {}).str

    file_path = file_path:gsub('/', string.format(' %s ', separator))

    local navic_ok, navic = pcall(require, 'nvim-navic')
    if not navic_ok or not navic.is_available() then
        return string.format('     %s', file_path)
    end

    return string.format('     %s %s %s', file_path, separator, navic.get_location())

    -- return '%#WinBarPath#' .. file_path .. '%*' .. '%#WinBarModified#' .. modified .. '%*'
end

return M
