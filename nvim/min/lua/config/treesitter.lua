local ts = require('nvim-treesitter.configs')

local plugins = {
	'bash',
	'java',
	'lua',
	'rust',
	'toml',
	'go',
	'gomod',
	'json',
	'jsonc',
	'python',
	'dockerfile',
	'cpp',
	'c',
	'regex'
}

ts.setup {
	ensure_installed = plugins,
	highlight = {
		enable = true
	},
	incrementalSelection = {
		enable = true
	},
	indent = {
		enable = true
	},
	textobjects = {
		select = {
			enable = true,
			keymaps = {
				['af'] = '@function.outer',
				['if'] = '@function.inner',
				['ac'] = '@class.outer',
				['ic'] = '@class.inner'
			}
		},
		lsp_interop = {
			enable = true,
			peek_definition_code = {
				['gp'] = '@function.outer',
				['gP'] = '@class.outer'
			}
		},
		move = {
			enable = true,
			goto_next_start = {
				[']m'] = '@function.outer',
				[']]'] = '@class.outer'
			},
			goto_next_end = {
				[']M'] = '@function.outer',
				[']['] = '@class.outer'
			},
			goto_previous_start = {
				['[m'] = '@function.outer',
				['[['] = '@class.outer'
			},
			goto_previous_end = {
				['[M'] = '@function.outer',
				['[]'] = '@class.outer'
			}
		}
	}
}
