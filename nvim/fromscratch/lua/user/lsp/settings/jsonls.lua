-- local default_schemas = nil
-- local status_ok, jsonls_settings = pcall(require, 'nlspsettings.jsonls')
-- if status_ok then
--     default_schemas = jsonls_settings.get_default_schemas()
-- end
local store_ok, store = pcall(require, 'schemastore')
local store_schemas = nil
if store_ok then
    store_schemas = store.json.schemas()
end

-- local local_schemas = {
--     -- {
--     --     description = 'Microsoft terminal configuration file',
--     --     fileMatch = { 'settings.json' },
--     --     url = 'https://aka.ms/terminal-profiles-schema',
--     -- },
-- }

-- local function extend(tab1, tab2)
--     if not tab2 then
--         return
--     end
--     for _, value in ipairs(tab2) do
--         table.insert(tab1, value)
--     end
--     return tab1
-- end

-- local extended_schemas = extend(store_schemas, default_schemas)
-- extended_schemas = extend(local_schemas, extended_schemas)

local opts = {
    settings = {
        json = {
            schemas = store_schemas,
            validate = {
                enable = true
            }
        },
    },
    setup = {
        commands = {
            Format = {
                function()
                    vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line('$'), 0 })
                end,
            },
        },
    },
}

return opts
