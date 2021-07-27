local ts = require('nvim-treesitter.configs')
-- local parser = require "nvim-treesitter.parsers".get_parser_configs()

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

-- parser.markdown = {
--   install_info = {
--     url = 'https://github.com/ikatyang/tree-sitter-markdown', -- local path or git repo
--     files = { 'src/parser.c', 'src/scanner.cc', '-DTREE_SITTER_MARKDOWN_AVOID_CRASH=1' }
--   },
--   filetype = 'markdown', -- if filetype does not agrees with parser name
-- }

ts.setup {
	ensure_installed = plugins,
	highlight = {
		enable = true
	},
	incrementalSelection = {
		enable = true
	},
	indent = {
		enable = true,
		disable = {'java', 'json'}
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
