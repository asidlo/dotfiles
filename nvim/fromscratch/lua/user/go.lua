local status_ok, go = pcall(require, 'go')
if not status_ok then
    return
end

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local fmt_sync_grp = augroup('user_go', { clear = true })

autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimport()
    end,
    group = fmt_sync_grp,
})

go.setup({
    lsp_keymaps = false,
    lsp_gofumpt = true,
    dap_debug = false,
    dap_debug_gui = false,
})
