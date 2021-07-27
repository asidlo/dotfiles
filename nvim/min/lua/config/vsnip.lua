local vsnip_expand = function ()
	if vim.fn.call('vsnip#available(1)') then
		return replace_termcodes('<Plug>(vsnip-expand-or-jump)')
	else
		return replace_termcodes('<C-j>')
	end
end

-- set_keymap('i', '<C-j>', vsnip_expand(), { expr = true })
-- set_keymap('s', '<C-j>', vsnip_expand(), { expr = true })
-- set_keymap('i', '<Tab>', vsnip_expand(), { expr = true })
