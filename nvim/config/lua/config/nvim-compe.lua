local snippets = require('snippets')
local compe = require('compe')

compe.setup{
  enabled = true,
  source = {
    path = true,
    buffer = true,
    nvim_lsp = true,
    nvim_lua = true,
    -- ultisnips = true,
    snippets_nvim = true,
    nvim_treesitter = true,
    spell = true,
  };
}

vim.api.nvim_set_keymap('i', '<C-Space>', 'compe#complete()', {noremap = true, silent = true, expr = true})
vim.api.nvim_set_keymap('i', '<CR>', 'compe#confirm({"select": v:true, "keys": "<CR>"})', {noremap = true, silent = true, expr = true})

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
    return replace_termcodes("<C-n>")
  elseif snippets.has_active_snippet() then
    snippets.expand_or_advance(1)
  elseif check_back_space() then
    return replace_termcodes("<Tab>")
  else
    return vim.fn['compe#complete']()
  end
end

function _G.s_tab_complete()
  if vim.fn.pumvisible() == 1 then
    return replace_termcodes("<C-p>")
  elseif snippets.has_active_snippet() then
    snippets.expand_or_advance(-1)
  else
    return replace_termcodes("<S-Tab>")
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", 'v:lua.tab_complete()', {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
