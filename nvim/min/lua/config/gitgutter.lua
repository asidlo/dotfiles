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

vim.g.gitgutter_map_keys = 0
set_keymap('n', ']h', '<Cmd>GitGutterNextHunk<CR>')
set_keymap('n', '[h', '<Cmd>GitGutterPrevHunk<CR>')
set_keymap('n', '<Leader>hs', '<Cmd>GitGutterStageHunk<CR>')
set_keymap('n', '<Leader>hu', '<Cmd>GitGutterUndoHunk<CR>')
set_keymap('n', '<Leader>hp', '<Cmd>GitGutterPreviewHunk<CR>')
set_keymap('o', 'ih', 'v:lua.gitgutter_inner_pending()', {
	expr = true
})
set_keymap('o', 'ah', 'v:lua.gitgutter_outer_pending()', {
	expr = true
})
set_keymap('x', 'ih', 'v:lua.gitgutter_inner_visual()', {
	expr = true
})
set_keymap('x', 'ah', 'v:lua.gitgutter_outer_visual()', {
	expr = true
})
