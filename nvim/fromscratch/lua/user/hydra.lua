local ok, hydra = pcall(require, 'hydra')
if not ok then
    return
end

local M = {}

local bottom_hint = {
    position = 'bottom',
    border = 'rounded'
}

M.config = {
    {
        name = 'Scroll',
        mode = 'n',
        body = 'z',
        heads = {
            { 'h', '5zh' },
            { 'l', '5zl', { desc = '←/→' } },
            { 'H', 'zH' },
            { 'L', 'zL', { desc = 'half screen ←/→' } },
        },
        config = {
            hint = bottom_hint
        }
    },
    {
        name = 'Window',
        mode = { 'n', 't' },
        body = '<C-w>',
        heads = {
            { 'h', '<C-\\><C-N><C-w>h' },
            { 'j', '<C-\\><C-N><C-w>j' },
            { 'k', '<C-\\><C-N><C-w>k' },
            { 'l', '<C-\\><C-N><C-w>l', { desc = 'navigate' } },
            { '+', '<C-\\><C-N><C-w>+' },
            { '-', '<C-\\><C-N><C-w>-', { desc = '+/- size' } },
        },
        config = {
            timeout = 4000,
            hint = bottom_hint
        }
    }
}

M.setup = function()
    for _, cfg in ipairs(M.config) do
        hydra(cfg)
    end
end

return M
