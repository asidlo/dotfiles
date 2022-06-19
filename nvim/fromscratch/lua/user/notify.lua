local M = {}

local opts = {
    ---@usage Animation style one of { "fade", "slide", "fade_in_slide_out", "static" }
    stages = "slide",

    ---@usage Function called when a new window is opened, use for changing win settings/config
    on_open = nil,

    ---@usage Function called when a window is closed
    on_close = nil,

    ---@usage timeout for notifications in ms, default 5000
    timeout = 5000,

    -- Render function for notifications. See notify-render()
    render = "default",

    ---@usage highlight behind the window for stages that change opacity
    background_colour = "#000000",

    ---@usage minimum width for notification windows
    minimum_width = 40,

    max_width = 80,

    max_height = 40,

    ---@usage Icons for the different levels
    icons = {
        ERROR = "",
        WARN = "",
        INFO = "",
        DEBUG = "",
        TRACE = "✎",
    },
}

function M.setup()
    if #vim.api.nvim_list_uis() == 0 then
        -- no need to configure notifications in headless
        return
    end

    local ok, notify = pcall(require, 'notify')
    if not ok then
        vim.notify('Missing notify', vim.log.levels.WARN)
        return
    end

    notify.setup(opts)
    vim.notify = notify
end

local format_json = function(msg)
    local json = require("JSON")
    return json:encode_pretty(msg, nil, {
        pretty = true,
        align_keys = false,
        array_newline = true,
        indent = "  "
    })
end

M.info = function(title, msg)
    vim.notify(format_json(msg), vim.log.levels.INFO, {
        title = title,
        on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            vim.api.nvim_buf_set_option(buf, "filetype", "json")
        end,
    })
end

M.debug = function(title, msg)
    vim.notify(format_json(msg), vim.log.levels.DEBUG, {
        title = title,
        on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            vim.api.nvim_buf_set_option(buf, "filetype", "json")
        end,
    })
end

M.warn = function(title, msg)
    vim.notify(format_json(msg), vim.log.levels.WARN, {
        title = title,
        on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            vim.api.nvim_buf_set_option(buf, "filetype", "json")
        end,
    })
end

M.error = function(title, msg)
    vim.notify(format_json(msg), vim.log.levels.ERROR, {
        title = title,
        on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            vim.api.nvim_buf_set_option(buf, "filetype", "json")
        end,
    })
end

return M
