local cmp_status_ok, cmp = pcall(require, 'cmp')
if not cmp_status_ok then
    return
end

local cmp_nuget_ok, cmp_nuget = pcall(require, 'cmp-nuget')
if cmp_nuget_ok then
    cmp_nuget.setup({})
end

local snip_status_ok, luasnip = pcall(require, 'luasnip')
if not snip_status_ok then
    return
end

require('luasnip/loaders/from_vscode').lazy_load()

local check_backspace = function()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s')
end

local has_words_before = function()
    local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

--   פּ ﯟ   some other good icons
-- local kind_icons = {
--     Text = '',
--     Method = 'm',
--     Function = '',
--     Constructor = '',
--     Field = '',
--     Variable = '',
--     Class = '',
--     Interface = '',
--     Module = '',
--     Property = '',
--     Unit = '',
--     Value = '',
--     Enum = '',
--     Keyword = '',
--     Snippet = '',
--     Color = '',
--     File = '',
--     Reference = '',
--     Folder = '',
--     EnumMember = '',
--     Constant = '',
--     Struct = '',
--     Event = '',
--     Operator = '',
--     TypeParameter = '',
-- }

local kind_icons = {
    Class = ' ',
    Color = ' ',
    Constant = 'ﲀ ',
    Constructor = ' ',
    Enum = '練',
    EnumMember = ' ',
    Event = ' ',
    Field = ' ',
    File = '',
    Folder = ' ',
    Function = ' ',
    Interface = 'ﰮ ',
    Keyword = ' ',
    Method = ' ',
    Module = ' ',
    Operator = '',
    Property = ' ',
    Reference = ' ',
    Snippet = ' ',
    Struct = ' ',
    Text = ' ',
    TypeParameter = ' ',
    Unit = '塞',
    Value = ' ',
    Variable = ' ',
}
local source_names = {
    nvim_lsp = '(LSP)',
    emoji = '(Emoji)',
    path = '(Path)',
    calc = '(Calc)',
    cmp_tabnine = '(Tabnine)',
    vsnip = '(Snippet)',
    luasnip = '(Snippet)',
    buffer = '(Buffer)',
    tmux = '(TMUX)',
}
local duplicates = {
    buffer = 1,
    path = 1,
    nvim_lsp = 0,
    luasnip = 1,
}
-- find more here: https://www.nerdfonts.com/cheat-sheet

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
        end,
    },
    mapping = {
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<Up>'] = cmp.mapping.select_prev_item(),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<Down>'] = cmp.mapping.select_next_item(),
        ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        -- Accept currently selected item. If none selected, `select` first item.
        -- Set `select` to `false` to only confirm explicitly selected items.
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
                -- elseif luasnip.expandable() then
                --     luasnip.expand()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif check_backspace() then
                fallback()
            else
                fallback()
            end
        end, {
            'i',
            's',
        }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {
            'i',
            's',
        }),
    },
    formatting = {
        fields = { 'kind', 'abbr', 'menu' },
        max_width = 0,
        kind_icons = kind_icons,
        source_names = source_names,
        duplicates = duplicates,
        duplicates_default = 0,
        format = function(entry, vim_item)
            local max_width = 0
            if max_width ~= 0 and #vim_item.abbr > max_width then
                vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. '…'
            end
            vim_item.kind = kind_icons[vim_item.kind]
            vim_item.menu = source_names[entry.source.name]
            vim_item.dup = duplicates[entry.source.name] or 0
            return vim_item
        end,
        -- format = function(entry, vim_item)
        --     -- Kind icons
        --     vim_item.kind = string.format('%s', kind_icons[vim_item.kind])
        --     -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
        --     vim_item.menu = ({
        --         nvim_lsp = '[LSP]',
        --         omni = '[Omni]',
        --         luasnip = '[Snippet]',
        --         buffer = '[Buffer]',
        --         path = '[Path]',
        --         spell = '[Spell]',
        --         nvim_lua = '[Lua]',
        --         -- dictionary = '[Dict]',
        --     })[entry.source.name]
        --     return vim_item
        -- end,
        -- source_names = {
        --     nuget = '(NuGet)',
        -- },
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'luasnip' },
        { name = 'cmp_tabnine' },
        { name = 'nvim_lua' },
        { name = 'buffer' },
        { name = 'calc' },
        { name = 'emoji' },
        { name = 'treesitter' },
        { name = 'crates' },
        { name = 'tmux' },
        -- { name = 'nvim_lsp' },
        -- { name = 'luasnip' },
        -- { name = 'omni' },
        -- { name = 'buffer' },
        -- { name = 'path' },
        -- { name = 'nvim_lua' },
        -- { name = 'spell' },
        -- -- {
        -- --     name = 'dictionary',
        -- --     keyword_length = 2,
        -- -- },
        -- { name = 'crates' },
        -- {
        --     name = 'nuget',
        --     keyword_length = 0,
        -- },
    },
    confirm_opts = {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
    },
    window = {
        -- documentation = {
        --     border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
        -- },
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    experimental = {
        ghost_text = true,
        native_menu = false,
    },
    completion = {
        completeopt = 'menu,menuone,noinsert',
    },
})

-- require('cmp').setup.cmdline(':', {
--     sources = {
--         { name = 'cmdline' },
--     },
--     mapping = {
--         ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'c' }),
--         ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
--         ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
--         ['<C-f>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
--         ['<C-y>'] = cmp.mapping(cmp.mapping.confirm({ select = true }), { 'c' }),
--         ['<C-e>'] = cmp.mapping({ c = cmp.mapping.close() }),
--     },
--     completion = {
--         completeopt = 'menu,menuone,noselect',
--     },
-- })
--
-- require('cmp').setup.cmdline('/', {
--     sources = {
--         { name = 'buffer' },
--     },
--     mapping = {
--         ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'c' }),
--         ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
--         ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
--         ['<C-f>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
--         ['<C-y>'] = cmp.mapping(cmp.mapping.confirm({ select = true }), { 'c' }),
--         ['<C-e>'] = cmp.mapping({ c = cmp.mapping.close() }),
--     },
--     completion = {
--         completeopt = 'menu,menuone,noselect',
--     },
-- })
--
-- require('cmp_dictionary').setup({
--     dic = {
--         ['markdown'] = '/usr/share/dict/words',
--         ['text'] = '/usr/share/dict/words',
--         ['gitcommit'] = '/usr/share/dict/words',
--     },
--     -- The following are default values, so you don't need to write them if you don't want to change them
--     exact = 2,
--     async = false,
--     capacity = 5,
--     debug = false,
-- })
