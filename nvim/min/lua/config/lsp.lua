-- Until they release the `vim.lsp.util.formatexpr()`
-- https://github.com/neovim/neovim/issues/12528
-- https://github.com/neovim/neovim/pull/12547
-- https://github.com/neovim/neovim/pull/13138
--
--- Implements an LSP `formatexpr`-compatible
-- @param start_line 1-indexed line, defaults to |v:lnum|
-- @param end_line 1-indexed line, calculated based on {start_line} and |v:count|
-- @param timeout_ms optional, defaults to 500ms
function _G.lsp_formatexpr(start_line, end_line, timeout_ms)
	timeout_ms = timeout_ms or 500

	if not start_line or not end_line then
		if vim.fn.mode() == 'i' or vim.fn.mode() == 'R' then
			-- `formatexpr` is also called when exceeding `textwidth` in insert mode
			-- fall back to internal formatting
			return 1
		end
		start_line = vim.v.lnum
		end_line = start_line + vim.v.count - 1
	end

	if start_line > 0 and end_line > 0 then
		local end_char = vim.fn.col('$')
		vim.lsp.buf.range_formatting({}, {start_line, 0}, {end_line, end_char})
	end

	-- do not run builtin formatter.
	return 0
end

local lspconfig = require('lspconfig')

local on_attach = function(client, _)
	-- Keybindings for LSPs
	-- Note these are in on_attach so that they don't override bindings in a non-LSP setting
	-- vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true, silent = true})
	-- vim.api.nvim_set_keymap('n', '<C-K>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', {noremap = true, silent = true})

	set_buf_keymap(0, 'n', '<F18>', '<Cmd>lua vim.lsp.buf.rename()<CR>')
	set_keymap('n', '<M-CR>', '<Cmd>lua vim.lsp.buf.code_action()<CR>')
	set_keymap('x', '<M-CR>', '<Cmd>lua vim.lsp.buf.range_code_action()<CR>')

	-- vim.api.nvim_set_keymap('n', 'g[', '<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', {noremap = true, silent = true})
	-- vim.api.nvim_set_keymap('n', 'g]', '<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>', {noremap = true, silent = true})

	set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
	set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.implementation()<CR>')
	set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>')
	set_keymap('n', '1gD', '<Cmd>lua vim.lsp.buf.type_definition()<CR>')
	set_buf_keymap(0, 'n', '<F6>', '<Cmd>lua vim.lsp.buf.references()<CR>')

	-- set_keymap('n', 'g0', '<Cmd>lua vim.lsp.buf.document_symbol()<CR>')
	-- set_keymap('n', 'gW', '<Cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
	-- set_keymap('n', '<M-Space>', "<Cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")

	-- vim.api.nvim_buf_set_keymap(0, 'n', '<F6>', '<Cmd>Telescope lsp_references<CR>', {noremap = true, silent = true})

	set_keymap('n', 'g0', '<Cmd>Telescope lsp_document_symbols<CR>')
	set_keymap('n', 'gW', '<Cmd>Telescope lsp_workspace_symbols<CR>')

	-- vim.api.nvim_set_keymap('n', '<M-CR>', '<Cmd>Telescope lsp_code_actions<CR>', {noremap = true, silent = true})
	-- vim.api.nvim_set_keymap('x', '<M-CR>', '<Cmd>Telescope lsp_range_code_actions<CR>', {noremap = true, silent = true})

	set_buf_keymap(0, 'n', 'K', "<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>")
	set_keymap('i', '<M-k>', "<Cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>")

	-- set_keymap(0, 'n', '<F18>', "<Cmd>lua require('lspsaga.rename').rename()<CR>")
	-- vim.api.nvim_set_keymap('n', '<M-CR>', "<Cmd>lua require('lspsaga.codeaction').code_action()<CR>", {noremap = true, silent = true})
	-- vim.api.nvim_set_keymap('x', '<M-CR>', "<Cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>", {noremap = true, silent = true})

	set_keymap('n', 'g[', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
	set_keymap('n', 'g]', "<Cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
	set_keymap('n', '<M-Space>', "<Cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>")
	set_keymap('n', 'gK', "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>")
	set_buf_keymap(0, 'n', '<M-f>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>")
	set_buf_keymap(0, 'n', '<M-b>', "<Cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>")

	if client.resolved_capabilities.document_range_formatting then
		-- Note that v:lua only supports global functions
		vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.lsp_formatexpr()')
	end

	if client.resolved_capabilities.document_formatting then
		set_buf_keymap(0, 'n', 'g=', '<Cmd>lua vim.lsp.buf.formatting()<CR>')
	end

	vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
	vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
		update_in_insert = true
	})

	-- Set autocommands conditional on server_capabilities
	if client.resolved_capabilities.document_highlight then
		vim.api.nvim_command [[
	  :hi LspReferenceRead guibg=NONE gui=underline term=underline cterm=underline
	  :hi LspReferenceText guibg=NONE gui=underline term=underline cterm=underline
	  :hi LspReferenceWrite guibg=NONE gui=underline term=underline cterm=underline
	]]
		nvim_create_augroups({
			lsp_document_highlight = {
				{'CursorHold <buffer> lua vim.lsp.buf.document_highlight()'},
				{'CursorMoved <buffer> lua vim.lsp.buf.clear_references()'}
			}
		})
	end
end

-- see :h lsp-handler
-- function(err, method, result, client_id, bufnr, config)
local status_callback = vim.schedule_wrap(function(_, _, result)
	-- vim.api.nvim_command(string.format(":echohl Function | echo '%s' | echohl None", result.message))
	print(result.message)
end)

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- https://github.com/neovim/neovim/issues/12970
vim.lsp.util.apply_text_document_edit = function(text_document_edit, _)
	local text_document = text_document_edit.textDocument
	local bufnr = vim.uri_to_bufnr(text_document.uri)

	vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr)
end

lspconfig.rust_analyzer.setup {
	on_attach = on_attach,
	capabilities = capabilities
}

lspconfig.gopls.setup {
	on_attach = on_attach,
	cmd = {'gopls', '-remote=auto'},
	root_dir = lspconfig.util.root_pattern('go.mod', '.git'),
	settings = {
		gopls = {
			analyses = {
				unusedparams = true
			},
			staticcheck = true
		}
	}
}

lspconfig.jdtls.setup {
	cmd = {'jdtls.sh'},
	on_attach = on_attach,
	root_dir = lspconfig.util.root_pattern('.git', 'gradlew', 'mvnw', '.java', '.groovy', '.gradle'),
	handlers = {
		['language/status'] = status_callback
	},
	init_options = {
		extendedClientCapabilities = {
			classFileContentsSupport = true,
			generateToStringPromptSupport = true,
			hashCodeEqualsPromptSupport = true,
			advancedExtractRefactoringSupport = true,
			advancedOrganizeImportsSupport = true,
			generateConstructorsPromptSupport = true,
			generateDelegateMethodsPromptSupport = true,
			inferSelectionSupport = {'extractMethod', 'extractVariable'},
			resolveAdditionalTextEditsSupport = true
		}
	},
	settings = {
		java = {
			signitureHelp = { enabled = true },
			contentProvider = { preferred = 'fernflower' }
		}
	},
	capabilities = capabilities
}

local system_name
if vim.fn.has("mac") == 1 then
	system_name = "macOS"
elseif vim.fn.has("unix") == 1 then
	system_name = "Linux"
elseif vim.fn.has('win32') == 1 then
	system_name = "Windows"
else
	print("Unsupported system for sumneko")
end

-- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
local sumneko_root_path = vim.fn.expand('~/.local/src/lua-language-server')
local sumneko_binary = sumneko_root_path .. "/bin/" .. system_name .. "/lua-language-server"

local luadev = require("lua-dev").setup({
	-- add any options here, or leave empty to use the default settings
	lspconfig = {
		cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
		on_attach = on_attach,
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = 'LuaJIT',
					-- Setup your lua path
					path = vim.split(package.path, ';')
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = {'vim', 'use'}
				},
				workspace = {
					-- Make the server aware of Neovim runtime files
					library = {
						[vim.fn.expand('$VIMRUNTIME/lua')] = true,
						[vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
					}
				}
			}
		}
	}
})
lspconfig.sumneko_lua.setup(luadev)
