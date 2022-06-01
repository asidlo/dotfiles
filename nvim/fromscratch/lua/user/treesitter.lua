local status_ok, configs = pcall(require, 'nvim-treesitter.configs')
if not status_ok then
    return
end

local modules = {}
if vim.env.TS_MODULES ~= nil then
    modules = vim.fn.split(vim.env.TS_MODULES, ',')
else
    local server_dir = vim.fn.glob('~/.local/share/nvim/site/pack/packer/start/nvim-treesitter/parser/')
    if vim.fn.empty(server_dir) == 0 then
        local cmd = 'fd -I -t f -e so -d 1 . ' .. server_dir .. ' -x echo {/.}'
        modules = vim.fn.systemlist(cmd)
    end
end
vim.env.TS_MODULES_INSTALLED = vim.fn.join(modules, ',')

configs.setup({
    ensure_installed = modules, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
    ignore_install = {}, -- List of parsers to ignore installing
    autopairs = {
        enable = true,
    },
    highlight = {
        enable = true, -- false will disable the whole extension
        disable = { '' }, -- list of language that will be disabled
        additional_vim_regex_highlighting = true,
    },
    indent = { enable = true, disable = { 'yaml', 'json', 'java', 'c', 'python' } },
    context_commentstring = {
        enable = true,
        enable_autocmd = false,
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<CR>',
            scope_incremental = '<CR>',
            node_incremental = '<TAB>',
            node_decremental = '<S-TAB>',
        },
    },
    text_objects = {
        select = {
            enable = true,
            keymaps = {
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
            },
        },
        move = {
            enable = true,
            goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.outer' },
            goto_next_end = { [']M'] = '@function.outer', [']['] = '@class.outer' },
            goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.outer' },
            goto_previous_end = { ['[M'] = '@function.outer', ['[]'] = '@class.outer' },
        },
        swap = {
            enable = false,
        },
        -- lsp_interop = { enable = true, peek_definition_code = { ['gp'] = '@function.outer', ['gP'] = '@class.outer' } },
    },
})
