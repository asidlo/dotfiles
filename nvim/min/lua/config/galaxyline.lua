local gl = require('galaxyline')
local colors = require('galaxyline.theme').default
local condition = require('galaxyline.condition')
local fileinfo = require('galaxyline.provider_fileinfo')
local vcs = require('galaxyline.provider_vcs')
local ext = require('galaxyline.provider_extensions')
local gls = gl.section

gl.short_line_list = {'NvimTree','dbui','packer'}

local separators = {bLeft = '	', bRight = ' ', uLeft = ' ', uTop = ' '}

local mode_map = {
	n = { color = colors.violet, label = 'NRM', description = 'Normal' },
	no = {color = colors.violet, label = 'OPP', description = 'Operator-pending'},
	nov = {color = colors.violet, label = 'OPP', description = 'Operator-pending (forced charwise o_v)'},
	noV = {color = colors.violet, label = 'OPP', description = 'Operator-pending (forced linewise o_V)'},
	['no'] = {color = colors.violet, label = 'OPP', description = 'Operator-pending (forced blockwise o_CTRL-V)'},
	niI = {color = colors.violet, label = 'NRM', description = 'Normal using i_CTRL-O in Insert-mode'},
	niR = {color = colors.violet, label = 'NRM', description = 'Normal using i_CTRL-O in Replace-mode'},
	niV = {color = colors.violet, label = 'NRM', description = 'Normal using |i_CTRL-O| in |Virtual-Replace-mode|'},
	v = {color = colors.blue, label = 'VIS', description = 'Visual by character'},
	V = {color = colors.blue, label = 'VIS', description = 'Visual by line'},
	[''] = {color = colors.blue, label = 'VIS', description = 'Visual blockwise'},
	s = {color = colors.yellow, label = 'SEL', description = 'Select by character'},
	S = {color = colors.yellow, label = 'SEL', description = 'Select by line'},
	[''] = {color = colors.yellow, label = 'SEL', description = 'Select blockwise'},
	i = {color = colors.green, label = 'INS', description = 'Insert'},
	ic = {color = colors.green, label = 'CPL', description = 'Insert mode completion |compl-generic|'},
	ix = {color = colors.green, label = 'CPL', description = 'Insert mode |i_CTRL-X| completion'},
	R = {color = colors.red, label = 'REP', description = 'Replace |R|'},
	Rc = {color = colors.red, label = 'REP', description = 'Replace mode completion |compl-generic|'},
	Rv = {color = colors.red, label = 'REP', description = 'Virtual Replace |gR|'},
	Rx = {color = colors.red, label = 'REP', description = 'Replace mode |i_CTRL-X| completion'},
	c	 = {color = colors.green, label = 'COM', description = 'Command-line editing'},
	cv = {color = colors.red, label = 'EXM', description = 'Vim Ex mode |gQ|'},
	ce	= {color = colors.red, label = 'EXM', description = 'Normal Ex mode |Q|'},
	r	 ={color = colors.fg, label = 'ENT', description = 'Hit-enter prompt'},
	rm = {color = colors.fg, label = 'MOR', description = 'The -- more -- prompt'},
	['r?'] = {color = colors.fg, label = 'CFM', description = '|:confirm| query of some sort'},
	['!']	= {color = colors.fg, label = 'SHE', description = 'Shell or external command is executing'},
	t	 = {color = colors.green, label = 'TER', description = 'Terminal mode: keys go to the job'}
}
-- gls.left[1] = {
--   LeftBar = {
--     provider = function() return '▊ ' end,
--     highlight = {colors.blue,colors.bg}
--   },
-- }

gls.left[1] = {
	ViMode = {
		provider = function()
		-- auto change color according the vim mode
			local mode = vim.fn.mode()
			local mode_opts = mode_map[mode]
			if mode_opts == nil then
				error("Undefined mode: "..mode)
			end
			vim.api.nvim_command('hi GalaxyViMode guibg='..mode_opts.color)
			return '  '..mode_opts.label
		end,
		highlight = {colors.bg,colors.bg,'bold'},
	},
}
-- gls.left[3] = {
--   FileSize = {
--     provider = 'FileSize',
--     condition = condition.buffer_not_empty,
--     highlight = {colors.fg,colors.bg}
--   }
-- }
gls.left[2] ={
	FileIcon = {
		provider = {function() return '  ' end, 'FileIcon'},
		condition = condition.buffer_not_empty,
		highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
	},
}

gls.left[3] = {
	FileName = {
		provider = 'FileName',
		condition = condition.buffer_not_empty,
		separator = separators.bLeft,
		highlight = {colors.fg,colors.bg,'bold'}
	}
}

local ts_statusline = function(config)
	return ' ' .. string.format('%s', vim.fn['nvim_treesitter#statusline'](config))
end

-- gls.left[6] = {
--   Treesitter = {
--     -- remember to increase the string length
--     -- icon filename.ext > icon class > icon function
--     condition =  function() return vim.fn['nvim_treesitter#statusline']() ~= vim.NIL end,
--     provider = ts_statusline,
--     highlight = {colors.green,colors.bg,'bold'}
--   }
-- }

-- gls.left[6] = {
--   Vista = {
--     provider = function() return ext.vista_nearest(' ') end,
--     condition = function()
--	 for _, client in ipairs(lsp_clients()) do
--	   if has_document_symbol_support(client) or has_document_definition_support(client) then
--	     return ext.vista_nearest('') ~= ''
--	   end
--	 end
--	 return false
--     end,
--     highlight = {colors.green,colors.bg,'bold'}
--   }
-- }

-- gls.left[8] = {
--   DiagnosticError = {
--     provider = 'DiagnosticError',
--     icon = '  ',
--     highlight = {colors.red,colors.bg}
--   }
-- }
-- gls.left[9] = {
--   DiagnosticWarn = {
--     provider = 'DiagnosticWarn',
--     icon = '  ',
--     highlight = {colors.yellow,colors.bg},
--   }
-- }

-- gls.left[10] = {
--   DiagnosticHint = {
--     provider = 'DiagnosticHint',
--     icon = '  ',
--     highlight = {colors.blue,colors.bg},
--   }
-- }

-- gls.left[11] = {
--   DiagnosticInfo = {
--     provider = 'DiagnosticInfo',
--     icon = '  ',
--     highlight = {colors.blue,colors.bg},
--   }
-- }

-- gls.right[1] = {
--   ShowLspClient = {
--     provider = 'GetLspClient',
--     condition = function ()
--	 local tbl = {['dashboard'] = true,['']=true}
--	 if tbl[vim.bo.filetype] then
--	   return false
--	 end
--	 return true
--     end,
--     icon = ' LSP:',
--     highlight = {colors.yellow,colors.bg},
--   }
-- }

gls.right[2] = {
	DiagnosticError = {
		provider = 'DiagnosticError',
		icon = ' ',
		highlight = {colors.red,colors.bg}
	}
}
gls.right[3] = {
	DiagnosticWarn = {
		provider = 'DiagnosticWarn',
		icon = ' ',
		highlight = {colors.yellow,colors.bg},
	}
}

gls.right[4] = {
	DiagnosticHint = {
		provider = 'DiagnosticHint',
		icon = ' ',
		highlight = {colors.blue,colors.bg},
	}
}

gls.right[5] = {
	DiagnosticInfo = {
		provider = 'DiagnosticInfo',
		icon = ' ',
		highlight = {colors.blue,colors.bg},
	}
}

gls.right[6] = {
	GitIcon = {
		provider = function() return ' ' end,
		-- condition = function() return vim.bo.filetype ~= 'help' or condition.check_git_workspace end,
		condition = function() return vim.bo.filetype ~= 'help' and condition.check_git_workspace() end,
		separator_highlight = {'NONE',colors.bg},
		highlight = {colors.violet,colors.bg,'bold'},
	}
}

gls.right[7] = {
	GitBranch = {
		provider = function() return trim(vcs.get_git_branch()) end,
		condition = condition.check_git_workspace,
		highlight = {colors.violet,colors.bg,'bold'},
	}
}

gls.right[8] = {
	DiffAdd = {
		provider = function() return trim(vcs.diff_add()) end,
		condition = condition.hide_in_width,
		icon = '   ',
		highlight = {colors.green,colors.bg},
	}
}
gls.right[9] = {
	DiffModified = {
		provider = function() return trim(vcs.diff_modified()) end,
		condition = condition.hide_in_width,
		icon = '   ',
		highlight = {colors.orange,colors.bg},
	}
}
gls.right[10] = {
	DiffRemove = {
		provider = function() return trim(vcs.diff_remove()) end,
		condition = condition.hide_in_width,
		icon = '   ',
		highlight = {colors.red,colors.bg},
	}
}

gls.right[11] = {
	LineInfo = {
		provider = 'LineColumn',
		separator_highlight = {'NONE',colors.bg},
		separator = ' ',
		highlight = {colors.fg,colors.bg,'bold'},
	},
}

gls.right[12] = {
	Percent = {
		provider = function() return trim(fileinfo.current_line_percent()) end,
		separator_highlight = {'NONE',colors.bg},
		separator = ' ',
		highlight = {colors.fg,colors.bg,'bold'},
	}
}

gls.right[13] = {
	FileEncode = {
		provider = function() return trim(fileinfo.get_file_encode()) end,
		condition = condition.hide_in_width and condition.buffer_not_empty,
		separator = ' ',
		separator_highlight = {'NONE',colors.bg},
		highlight = {colors.green,colors.bg,'bold'}
	}
}

gls.right[14] = {
	FileFormat = {
		provider = 'FileFormat',
		condition = condition.hide_in_width and condition.buffer_not_empty,
		separator = ' ',
		separator_highlight = {'NONE',colors.bg},
		highlight = {colors.green,colors.bg,'bold'}
	}
}

gls.right[15] = {
	RightBar = {
		provider = function() return '▊' end,
		separator = ' ',
		highlight = {colors.blue,colors.bg}
	},
}

gls.short_line_left[1] = {
	BufferType = {
		provider = 'FileTypeName',
		separator = ' ',
		separator_highlight = {'NONE',colors.bg},
		highlight = {colors.blue,colors.bg,'bold'}
	}
}

gls.short_line_left[2] = {
	SFileName = {
		provider =	'SFileName',
		condition = condition.buffer_not_empty,
		highlight = {colors.fg,colors.bg,'bold'}
	}
}

gls.short_line_right[1] = {
	BufferIcon = {
		provider= 'BufferIcon',
		highlight = {colors.fg,colors.bg}
	}
}
