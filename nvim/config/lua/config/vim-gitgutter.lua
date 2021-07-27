function _G.gitgutter_inner_pending()
  return replace_termcodes('<Plug>(GitGutterTextObjectInnerPending)')
end
function _G.gitgutter_outer_pending()
  return replace_termcodes('<Plug>(GitGutterTextObjectOuterPending)')
end
function _G.gitgutter_inner_visual()
  return replace_termcodes('<Plug>(GitGutterTextObjectInnerVisual)')
end
function _G.gitgutter_outer_visual()
  return replace_termcodes('<Plug>(GitGutterTextObjectOuterVisual)')
end

-- Note: the <Plug> mappings are found in after/plugin/gitgutter.vim
vim.g.gitgutter_map_keys = 0
vim.api.nvim_set_keymap('n', ']h', '<Cmd>GitGutterNextHunk<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '[h', '<Cmd>GitGutterPrevHunk<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>hs', '<Cmd>GitGutterStageHunk<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>hu', '<Cmd>GitGutterUndoHunk<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>hp', '<Cmd>GitGutterPreviewHunk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('o', 'ih', 'v:lua.gitgutter_inner_pending()', {expr = true})
vim.api.nvim_set_keymap('o', 'ah', 'v:lua.gitgutter_outer_pending()', {expr = true})
vim.api.nvim_set_keymap('x', 'ih', 'v:lua.gitgutter_inner_visual()', {expr = true})
vim.api.nvim_set_keymap('x', 'ah', 'v:lua.gitgutter_outer_visual()', {expr = true})
