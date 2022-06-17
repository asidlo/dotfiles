local M = {}

local change_colorscheme = function(name)
    vim.cmd({ cmd = 'colorscheme', args = { name } })
end

local push_error = function(error)
    if not M.err then
        M.err = {}
    end
    table.insert(M.err, error)
end

M.change = function(name, callback)
    vim.validate {
        name = { name, 'string', false },
        callback = { callback, 'function', true },
    }

    M.name = name
    local ok, msg = pcall(change_colorscheme, name)
    if not ok then
        push_error(string.format('Unable to change colorscheme; %s', msg))
        return
    end

    if callback then
        local ok, msg = pcall(callback)
        if not ok then
            push_error(string.format('Unable to execute colorscheme.change(' % s ') callback; %s', name, msg))
            return
        end
    end

    M.err = nil
end

local ok_colors, colors = pcall(require, 'tokyonight.colors')
if not ok_colors then
    M.change('default', function()
        vim.cmd({ cmd = 'highlight', args = { 'link', 'FloatBorder', 'Normal' } })
        vim.cmd({ cmd = 'highlight', args = { 'link', 'NormalFloat', 'Normal' } })
        vim.api.nvim_set_hl(0, 'DiffDelete', { bg = nil, fg = 'red' })
        vim.api.nvim_set_hl(0, 'DiffAdd', { bg = nil, fg = 'green' })
        vim.api.nvim_set_hl(0, 'DiffChange', { bg = nil, fg = 'yellow' })
        vim.api.nvim_set_hl(0, 'SignColumn', { bg = nil })
    end)
    push_error('Missing tokyonight.colors')
else
    M.colors = colors.setup()
    M.change('tokyonight', function()
        vim.api.nvim_set_hl(0, 'NormalFloat', { bg = colors.bg })
        vim.api.nvim_set_hl(0, 'FloatBorder', { bg = colors.bg })
    end)
end

vim.g.colors_name = M.name

return M
