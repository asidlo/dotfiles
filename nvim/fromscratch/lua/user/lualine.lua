local status_ok, lualine = pcall(require, 'lualine')
if not status_ok then
    return
end

local colors = require('tokyonight.colors').setup()

local hide_in_width = function()
    return vim.fn.winwidth(0) > 80
end

local diagnostics = {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    sections = { 'error', 'warn' },
    symbols = { error = ' ', warn = ' ' },
    colored = true,
    diagnostics_color = {
        error = { fg = colors.red },
        warn = { fg = colors.yellow },
        info = { fg = colors.fg },
        hint = { fg = colors.cyan },
    },
    update_in_insert = false,
    always_visible = false,
}

local diff = {
    'diff',
    colored = true,
    diff_color = {
        added = { fg = colors.git.add },
        modified = { fg = colors.git.change },
        removed = { fg = colors.git.delete },
    },
    symbols = { added = ' ', modified = ' ', removed = ' ' },
    cond = hide_in_width,
}

local mode = {
    'mode',
    fmt = function(str)
        return '-- ' .. str .. ' --'
    end,
}

local branch = {
    'branch',
    icons_enabled = true,
    icon = '',
}

local env_cleanup = function(venv)
    if string.find(venv, '/') then
        local final_venv = venv
        for w in venv:gmatch('([^/]+)') do
            final_venv = w
        end
        venv = final_venv
    end
    return venv
end

local pyenv = {
    function()
        if vim.bo.filetype == 'python' then
            local venv = os.getenv('CONDA_DEFAULT_ENV')
            if venv then
                return string.format('  (%s)', env_cleanup(venv))
            end
            venv = os.getenv('VIRTUAL_ENV')
            if venv then
                return string.format('  (%s)', env_cleanup(venv))
            end
            return ''
        end
        return ''
    end,
    color = { fg = colors.green },
    cond = hide_in_width,
}

local lsp_progress = {
    function()
        local Lsp = vim.lsp.util.get_progress_messages()[1]

        if vim.o.columns < 120 or not Lsp then
            return ''
        end

        local msg = Lsp.message or ''
        local percentage = Lsp.percentage or 0
        local title = Lsp.title or ''
        local spinners = { '', '' }
        local ms = vim.loop.hrtime() / 1000000
        local frame = math.floor(ms / 120) % #spinners
        local content = string.format(' %%<%s %s %s (%s%%%%) ', spinners[frame + 1], title, msg, percentage)

        return ('%#St_LspProgress#' .. content) or ''
    end,
}

local spaces = function()
    return 'spaces: ' .. vim.api.nvim_buf_get_option(0, 'shiftwidth')
end

-- local omnisharp_status = function()
--     return vim.fn['sharpenup#statusline#Build']()
-- end

-- Check if running version 0.8.0+ if so then set globalstatus to true
-- {
--   api_compatible = 0,
--   api_level = 9,
--   api_prerelease = false,
--   major = 0,
--   minor = 7,
--   patch = 0
-- }
local use_globalstatus = false
local version = vim.version()
if version.major > 0 or version.minor >= 7 then
    use_globalstatus = true
end

local lsp_client = {
    function(msg)
        msg = msg or 'LS Inactive'
        local buf_clients = vim.lsp.buf_get_clients()
        if next(buf_clients) == nil then
            if type(msg) == 'boolean' or #msg == 0 then
                -- return "LS Inactive"
                return ''
            end
            return msg
        end

        local buf_client_names = {}

        -- add client
        for _, client in pairs(buf_clients) do
            -- if client.name ~= "null-ls" then
            table.insert(buf_client_names, client.name)
            -- end
        end

        if #buf_client_names > 1 then
            for index, value in ipairs(buf_client_names) do
                if value == 'null-ls' then
                    table.remove(buf_client_names, index)
                end
            end
        end

        return '  ' .. table.concat(buf_client_names, ', ')
    end,
    color = { gui = 'bold' },
    cond = hide_in_width,
}

-- local separators = { bLeft = '', bRight = ' ', uLeft = ' ', uTop = ' ' }

local disabled_filetypes = { 'alpha' }
if not use_globalstatus then
    disabled_filetypes = { 'alpha', 'NvimTree', 'Outline' }
end

local navic_ok, navic = pcall(require, 'nvim-navic')
if not navic_ok then
    return
end

lualine.setup({
    options = {
        icons_enabled = true,
        theme = 'tokyonight', -- TODO (AS): Figure out why 'auto' fails
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = disabled_filetypes,
        always_divide_middle = true,
        globalstatus = use_globalstatus,
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { branch, pyenv },
        lualine_c = { diff },
        -- lualine_x = { lsp_progress, diagnostics, lsp_client },
        lualine_x = { lsp_progress, diagnostics },
        lualine_y = { lsp_client },
        -- lualine_y = { 'encoding', 'fileformat', 'filetype' },
        lualine_z = { 'location' },
        -- lualine_a = {'mode'},
        -- lualine_b = {},
        -- lualine_c = { branch, pyenv, diagnostics, { gps.get_location, cond = gps.is_available } },
        -- -- lualine_x = { "encoding", "fileformat", "filetype" },
        -- -- lualine_x = { omnisharp_status, diff, 'location', spaces, 'encoding', 'fileformat', 'filetype' },
        -- lualine_x = { diff, 'location', spaces, 'encoding', 'fileformat', 'filetype' },
        -- lualine_y = {},
        -- lualine_z = {},
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
    },
    tabline = {},
    extensions = {},
})
