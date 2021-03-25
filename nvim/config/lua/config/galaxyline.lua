local gl = require('galaxyline')
local colors = require('galaxyline.theme').default
local condition = require('galaxyline.condition')
local fileinfo = require('galaxyline.provider_fileinfo')
local vcs = require('galaxyline.provider_vcs')
local ext = require('galaxyline.provider_extensions')
local gls = gl.section

gl.short_line_list = {'NvimTree','vista','dbui','packer'}

gls.left[1] = {
  LeftBar = {
    provider = function() return '▊ ' end,
    highlight = {colors.blue,colors.bg}
  },
}

gls.left[2] = {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
      local mode_color = {n = colors.red, i = colors.green,v=colors.blue,
                          [''] = colors.blue,V=colors.blue,
                          c = colors.magenta,no = colors.red,s = colors.orange,
                          S=colors.orange,[''] = colors.orange,
                          ic = colors.yellow,R = colors.violet,Rv = colors.violet,
                          cv = colors.red,ce=colors.red, r = colors.cyan,
                          rm = colors.cyan, ['r?'] = colors.cyan,
                          ['!']  = colors.red,t = colors.red}
      vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color[vim.fn.mode()])
      return '  '
      -- return '  '
    end,
    highlight = {colors.red,colors.bg,'bold'},
  },
}
-- gls.left[3] = {
--   FileSize = {
--     provider = 'FileSize',
--     condition = condition.buffer_not_empty,
--     highlight = {colors.fg,colors.bg}
--   }
-- }
gls.left[4] ={
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
  },
}

gls.left[5] = {
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
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

gls.left[6] = {
  Vista = {
    provider = function() return ext.vista_nearest(' ') end,
    condition = function()
      for _, client in ipairs(lsp_clients()) do
        if has_document_symbol_support(client) or has_document_definition_support(client) then
          return true
        end
      end
      return false
    end,
    highlight = {colors.green,colors.bg,'bold'}
  }
}

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

-- gls.mid[1] = {
--   ShowLspClient = {
--     provider = 'GetLspClient',
--     condition = function ()
--       local tbl = {['dashboard'] = true,['']=true}
--       if tbl[vim.bo.filetype] then
--         return false
--       end
--       return true
--     end,
--     icon = ' LSP:',
--     highlight = {colors.yellow,colors.bg,'bold'}
--   }
-- }

gls.right[1] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = ' ',
    highlight = {colors.red,colors.bg}
  }
}
gls.right[2] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = ' ',
    highlight = {colors.yellow,colors.bg},
  }
}

gls.right[3] = {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = ' ',
    highlight = {colors.blue,colors.bg},
  }
}

gls.right[4] = {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = ' ',
    highlight = {colors.blue,colors.bg},
  }
}

gls.right[5] = {
  GitIcon = {
    provider = function() return ' ' end,
    -- condition = function() return vim.bo.filetype ~= 'help' or condition.check_git_workspace end,
    condition = function() return vim.bo.filetype ~= 'help' and condition.check_git_workspace() end,
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.violet,colors.bg,'bold'},
  }
}

gls.right[6] = {
  GitBranch = {
    provider = function() return trim(vcs.get_git_branch()) end,
    condition = condition.check_git_workspace,
    highlight = {colors.violet,colors.bg,'bold'},
  }
}

gls.right[7] = {
  DiffAdd = {
    provider = function() return trim(vcs.diff_add()) end,
    condition = condition.hide_in_width,
    icon = '   ',
    highlight = {colors.green,colors.bg},
  }
}
gls.right[8] = {
  DiffModified = {
    provider = function() return trim(vcs.diff_modified()) end,
    condition = condition.hide_in_width,
    icon = '   ',
    highlight = {colors.orange,colors.bg},
  }
}
gls.right[9] = {
  DiffRemove = {
    provider = function() return trim(vcs.diff_remove()) end,
    condition = condition.hide_in_width,
    icon = '   ',
    highlight = {colors.red,colors.bg},
  }
}

gls.right[10] = {
  LineInfo = {
    provider = 'LineColumn',
    separator_highlight = {'NONE',colors.bg},
    separator = ' ',
    highlight = {colors.fg,colors.bg,'bold'},
  },
}

gls.right[11] = {
  Percent = {
    provider = function() return trim(fileinfo.current_line_percent()) end,
    separator_highlight = {'NONE',colors.bg},
    separator = ' ',
    highlight = {colors.fg,colors.bg,'bold'},
  }
}

gls.right[12] = {
  FileEncode = {
    provider = function() return trim(fileinfo.get_file_encode()) end,
    condition = condition.hide_in_width and condition.buffer_not_empty,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.green,colors.bg,'bold'}
  }
}

gls.right[13] = {
  FileFormat = {
    provider = 'FileFormat',
    condition = condition.hide_in_width and condition.buffer_not_empty,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.green,colors.bg,'bold'}
  }
}

gls.right[14] = {
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
    provider =  'SFileName',
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
