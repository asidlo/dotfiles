local compe = require('compe')
-- local snippets = require('snippets')
-- local utils = require('snippets.utils')
local luasnip = require('luasnip')

compe.setup {
    enabled = true,
    source = {
        path = true,
        buffer = true,
        nvim_lsp = true,
        nvim_lua = true,
        calc = false,
        emoji = false,
        snippets_nvim = false,
        luasnip = true, -- dont show to trigger with tab
        treesitter = false,
        spell = false
    }
}

-- TODO: var creates a variable, should use sub to have user fill in for now
-- TODO: cl should get class name for the default via the buffername
-- snippets.snippets = {
--     java = {
--         psvm = utils.match_indentation 'public static void main(String[] args) {\t${0}\n}',
--         sout = 'System.out.println(${1:i});$0',
--         cl = utils.match_indentation 'public class ${=vim.fn.expand("%:t:r")} {\t$0\n}',
--         pu = 'public ${1:type} ${2:name}$0',
--         pr = 'private ${1:type} ${2:name}$0',
--         psf = 'private static final ${1:type} ${2:name}$0',
--         pf = 'private final ${1:type} ${2:name}$0',
--         f = 'final $0'
--     }
-- }

local function check_back_space()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
function _G.tab_complete()
    if vim.fn.pumvisible() == 1 then
        return replace_termcodes('<C-n>')
        -- elseif snippets.has_active_snippet() then
        --     snippets.expand_or_advance(1)
    elseif luasnip.expand_or_jumpable() then
        return replace_termcodes("<cmd>lua require'luasnip'.expand_or_jump()<Cr>")
    elseif check_back_space() then
        return replace_termcodes('<Tab>')
    else
        return vim.fn['compe#complete']()
    end
end

function _G.s_tab_complete()
    if vim.fn.pumvisible() == 1 then
        return replace_termcodes('<C-p>')
        -- elseif snippets.has_active_snippet() then
        --     snippets.expand_or_advance(-1)
    elseif luasnip.jumpable(-1) then
        return replace_termcodes("<cmd>lua require'luasnip'.jump(-1)<CR>")
    else
        return replace_termcodes('<S-Tab>')
    end
end

set_keymap('i', '<C-Space>', 'compe#complete()', {noremap = true, silent = true, expr = true})
set_keymap('i', '<CR>', 'compe#confirm({"select": v:true, "keys": "<CR>"})', {noremap = true, silent = true, expr = true})
set_keymap('i', '<C-e>', 'compe#close("<c-e>")', {silent = true, expr = true})
set_keymap('i', '<Tab>', 'v:lua.tab_complete()', {silent = true, noremap = true, expr = true})
set_keymap('s', '<Tab>', 'v:lua.tab_complete()', {silent = true, noremap = true, expr = true})
set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', {silent = true, noremap = true, expr = true})
set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', {silent = true, noremap = true, expr = true})
-- set_keymap('i', '<C-k>', "<cmd>lua return require'snippets'.expand_or_advance(1)<CR>")
-- set_keymap('i', '<C-j>', "<cmd>lua return require'snippets'.advance_snippet(-1)<CR>")
