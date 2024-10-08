vim.cmd [[packadd nvim-web-devicons]]
local gl = require 'galaxyline'
local condition = require 'galaxyline.condition'
local fileinfo = require('galaxyline.provider_fileinfo')
local lsp = require('galaxyline.provider_lsp')

local gls = gl.section
gl.short_line_list = {'packer', 'NvimTree', 'Outline', 'LspTrouble'}

local separators = {bLeft = '', bRight = ' ', uLeft = ' ', uTop = ' '}

local colors = {
    bg = '#282a36',
    fg = '#f8f8f2',
    cyan = '#8be9fd',
    green = '#50fa7b',
    purple = '#bd93f9',
    orange = '#ffb86c',
    red = '#ff5555',
    yellow = '#f1fa8c',
    pink = '#ff79c6',
    comment = '#6272a4',
    selection = '#44475a',
    section_bg = '#38393f'
    -- middlegrey = '#8791A5',
    -- darkgrey = '#2c323d',
}

local function is_buffer_empty()
    -- Check whether the current buffer is empty
    return vim.fn.empty(vim.fn.expand('%:t')) == 1
end

local function has_width_gt(cols)
    -- Check if the windows width is greater than a given number of columns
    return vim.fn.winwidth(0) / 2 > cols
end

-- Local helper functions
local buffer_not_empty = function() return not is_buffer_empty() end

local checkwidth = function() return has_width_gt(35) and buffer_not_empty() end

local is_file = function() return vim.bo.buftype ~= 'nofile' end

local function has_value(tab, val)
    for _, value in ipairs(tab) do if value[1] == val then return true end end
    return false
end

local mode_color = function()
    local mode_colors = {
        [110] = colors.green,
        [105] = colors.cyan,
        [99] = colors.green,
        [116] = colors.cyan,
        [118] = colors.purple,
        [22] = colors.purple,
        [86] = colors.purple,
        [82] = colors.red,
        [115] = colors.red,
        [83] = colors.red
    }

    local color = mode_colors[vim.fn.mode():byte()]
    if color ~= nil then
        return color
    else
        return colors.purple
    end
end

local function file_readonly()
    if vim.bo.filetype == 'help' then return '' end
    if vim.bo.readonly == true then return '  ' end
    return ''
end

local function get_current_file_name()
    local file = vim.fn.expand '%:t'
    if vim.fn.empty(file) == 1 then return '' end
    if string.len(file_readonly()) ~= 0 then return file .. file_readonly() end
    if vim.bo.modifiable then if vim.bo.modified then return file .. '   ' end end
    return file .. ' '
end

local function split(str, sep)
    local res = {}
    local n = 1
    for w in str:gmatch('([^' .. sep .. ']*)') do
        res[n] = res[n] or w -- only set once (so the blank after a string is ignored)
        if w == '' then n = n + 1 end -- step forwards on a blank but not a string
    end
    return res
end

-- local function trailing_whitespace()
--     local trail = vim.fn.search('\\s$', 'nw')
--     if trail ~= 0 then
--         return '  '
--     else
--         return nil
--     end
-- end

-- local function tab_indent()
--     local tab = vim.fn.search('^\\t', 'nw')
--     if tab ~= 0 then
--         return ' → '
--     else
--         return nil
--     end
-- end

-- local function buffers_count()
--     local buffers = {}
--     for _, val in ipairs(vim.fn.range(1, vim.fn.bufnr('$'))) do
--         if vim.fn.bufexists(val) == 1 and vim.fn.buflisted(val) == 1 then
--             table.insert(buffers, val)
--         end
--     end
--     return #buffers
-- end

local function get_basename(file) return file:match '^.+/(.+)$' end

local GetGitRoot = function()
    local git_dir = require('galaxyline.provider_vcs').get_git_dir()
    if not git_dir then return '' end

    local git_root = git_dir:gsub('/.git/?$', '')
    return get_basename(git_root) .. ' '
end

-- local LspStatus = function()
--     if #vim.lsp.get_active_clients() > 0 then
--         return require('lsp-status').status()
--     end
--     return ''
-- end

-- local LspCheckDiagnostics = function()
--     if
--         #vim.lsp.get_active_clients() > 0
--         and diagnostic.get_diagnostic_error() == nil
--         and diagnostic.get_diagnostic_warn() == nil
--         and diagnostic.get_diagnostic_info() == nil
--         and require('lsp-status').status() == ' '
--     then
--         return ' '
--     end
--     return ''
-- end

-- Left side
gls.left[1] = {
    ViMode = {
        provider = function()
            local aliases = {
                [110] = 'NORMAL',
                [105] = 'INSERT',
                [99] = 'COMMAND',
                [116] = 'TERMINAL',
                [118] = 'VISUAL',
                [22] = 'V-BLOCK',
                [86] = 'V-LINE',
                [82] = 'REPLACE',
                [115] = 'SELECT',
                [83] = 'S-LINE'
            }
            vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
            local alias = aliases[vim.fn.mode():byte()]
            local mode
            if alias ~= nil then
                if has_width_gt(35) then
                    mode = alias
                else
                    mode = alias:sub(1, 1)
                end
            else
                mode = vim.fn.mode():byte()
            end
            return '  ' .. mode .. ' '
        end,
        highlight = {colors.bg, colors.bg, 'bold'}
    }
}
gls.left[2] = {
    FileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        condition = buffer_not_empty,
        highlight = {require('galaxyline.provider_fileinfo').get_file_icon, colors.selection}
    }
}
gls.left[3] = {
    FilePath = {
        provider = function()
            local fp = vim.fn.fnamemodify(vim.fn.expand '%', ':~:.:h')
            local tbl = split(fp, '/')
            local len = #tbl

            if len > 2 and not len == 3 and not tbl[0] == '~' then
                return '…/' .. table.concat(tbl, '/', len - 1) .. '/' -- shorten filepath to last 2 folders
                -- alternative: only 1 containing folder using vim builtin function
                -- return '…/' .. vim.fn.fnamemodify(vim.fn.expand '%', ':p:h:t') .. '/'
            else
                if string.len(fp) > 100 then return '…/' end
                return fp .. '/'
            end
        end,
        condition = function() return is_file() and checkwidth() end,
        highlight = {colors.comment, colors.selection}
    }
}
gls.left[4] = {
    FileName = {
        provider = get_current_file_name,
        condition = buffer_not_empty,
        highlight = {colors.fg, colors.selection}
        -- separator = separators.bLeft,
        -- separator_highlight = { colors.selection, colors.bg },
    }
}
gls.left[5] = {
    DiagnosticError = {
        provider = {'DiagnosticError'},
        icon = '  ',
        highlight = {colors.red, colors.selection}
        -- separator = ' ',
        -- separator_highlight = {colors.bg, colors.bg}
    }
}
gls.left[6] = {
    DiagnosticWarn = {
        provider = {'DiagnosticWarn'},
        icon = '  ',
        highlight = {colors.orange, colors.selection}
        -- separator = ' ',
        -- separator_highlight = {colors.bg, colors.bg}
    }
}
gls.left[7] = {
    DiagnosticInfo = {
        provider = {'DiagnosticInfo'},
        icon = '  ',
        highlight = {colors.cyan, colors.selection}
        -- separator = ' ',
        -- separator_highlight = {colors.selection, colors.bg}
    }
}
gls.left[8] = {
    DiagnosticHint = {
        provider = {'DiagnosticHint'},
        icon = '  ',
        highlight = {colors.fg, colors.selection}
        -- separator = ' ',
        -- separator_highlight = {colors.selection, colors.bg}
    }
}
-- gls.left[5] = {
--     WhiteSpace = {
--         provider = trailing_whitespace,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
-- gls.left[6] = {
--     TabIndent = {
--         provider = tab_indent,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
-- gls.left[8] = {
--     DiagnosticsCheck = {
--         provider = { LspCheckDiagnostics },
--         highlight = { colors.middlegrey, colors.bg },
--     },
-- }
-- gls.mid[1] = {
--     ShowLspClient = {
--         provider = 'GetLspClient',
--         condition = function()
--             if not has_width_gt(50) then return false end
--             local tbl = {['dashboard'] = true, [''] = true}
--             if tbl[vim.bo.filetype] then return false end
--             if lsp.get_lsp_client('none') == 'none' then return false end
--             return true
--         end,
--         icon = '    ',
--         highlight = {colors.fg, colors.selection},
--         separator = ' ',
--         separator_highlight = {colors.selection, colors.selection}
--     }
-- }
-- gls.left[14] = {
--     LspStatus = {
--         provider = { LspStatus },
--         -- separator = ' ',
--         -- separator_highlight = {colors.bg, colors.bg},
--         highlight = { colors.middlegrey, colors.bg },
--     },
-- }

-- Right side
gls.right[1] = {
    DiffAdd = {
        provider = 'DiffAdd',
        condition = checkwidth,
        icon = '+',
        highlight = {colors.green, colors.selection},
        separator = ' ',
        separator_highlight = {colors.fg, colors.selection}
    }
}
gls.right[2] = {
    DiffModified = {
        provider = 'DiffModified',
        condition = checkwidth,
        icon = '~',
        highlight = {colors.orange, colors.selection}
    }
}
gls.right[3] = {
    DiffRemove = {
        provider = 'DiffRemove',
        condition = checkwidth,
        icon = '-',
        highlight = {colors.red, colors.selection}
    }
}
gls.right[4] = {Space = {provider = function() return ' ' end, highlight = {colors.selection, colors.selection}}}
gls.right[5] = {
    GitBranch = {
        provider = {function() return '  ' end, 'GitBranch'},
        condition = condition.check_git_workspace,
        highlight = {colors.fg, colors.selection}
    }
}
-- Space required after branch name since GitRoot disappears on smaller buffers
gls.right[6] = {
    Space = {
        provider = function() return ' ' end,
        highlight = {colors.selection, colors.selection}
        -- condition = function()
        -- 	return not has_width_gt(50) and condition.check_git_workspace()
        -- end,
        -- highlight = { colors.selection, colors.bg },
    }
}
gls.right[7] = {
    GitRoot = {
        provider = {GetGitRoot},
        condition = function() return has_width_gt(50) and condition.check_git_workspace() end,
        icon = '   ',
        highlight = {colors.bg, colors.purple, 'bold'}
        -- separator = separators.uTop,
        -- separator_highlight = {colors.selection, colors.bg}
    }
}
gls.right[8] = {
    PerCent = {
        provider = function() return ' ' .. fileinfo.current_line_percent() end,
        condition = buffer_not_empty,
        highlight = {colors.bg, colors.cyan}
    }
}
-- gls.right[9] = {
--     ScrollBar = {
--         provider = 'ScrollBar',
--         highlight = {colors.purple, colors.selection}
--     }
-- }

-- Short status line
-- TODO: Figure out how to not display inactive for gl.short_line_list
-- gls.short_line_left[1] = {
-- 	ShortLineInactive = {
-- 		provider = function()
-- 			local ft = vim.bo.filetype
-- 			for _, value in ipairs(gl.short_line_list) do
-- 					if value[1] == ft then
-- 						return '  '..string.upper(ft)..' '
-- 					end
-- 				end
-- 			return '  INACTIVE '
-- 		end,
-- 		highlight = {colors.bg, colors.purple, 'bold'}
-- 	}
-- }
gls.short_line_left[1] = {
    ShortLineFileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        highlight = {require('galaxyline.provider_fileinfo').get_file_icon, colors.selection}
    }
}
gls.short_line_left[2] = {
    ShortLineFileName = {
        provider = {function() return string.format(' %s', get_current_file_name()) end},
        condition = buffer_not_empty,
        highlight = {colors.fg, colors.selection},
        separator = '',
        separator_highlight = {colors.selection, colors.selection}
    }
}

gls.short_line_right[1] = {
    ShortLineBufferIcon = {
        provider = {function() return ' ' end, 'BufferIcon'},
        highlight = {colors.fg, colors.selection},
        separator = ''
        -- separator_highlight = { colors.cyan, colors.cyan },
    }
}

-- Force manual load so that nvim boots with a status line
gl.load_galaxyline()
