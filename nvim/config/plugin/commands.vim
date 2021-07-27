command! LspLog exe '<mods>' 'split' v:lua.vim.lsp.get_log_path()
