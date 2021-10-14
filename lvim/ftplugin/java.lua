vim.cmd('setlocal expandtab tabstop=4 shiftwidth=4')
vim.cmd('setlocal foldlevel=2')
vim.cmd('setlocal colorcolumn=120')

-- ---Resolve the configuration for a server based on both common and user configuration
-- ---@param name string
-- ---@param user_config table [optional]
-- ---@return table
-- local function resolve_config(name, user_config)
--     local config = {
--         on_attach = require('lvim.lsp').common_on_attach,
--         on_init = require('lvim.lsp').common_on_init,
--         capabilities = require('lvim.lsp').common_capabilities(),
--     }

--     local status_ok, custom_config = pcall(require, 'lvim.lsp/providers/' .. name)
--     if status_ok then
--         config = vim.tbl_deep_extend('force', config, custom_config)
--     end

--     if user_config then
--         config = vim.tbl_deep_extend('force', config, user_config)
--     end

--     return config
-- end

-- local config = {
--     cmd = {
--         'jdtls.sh',
--         os.getenv('HOME') .. '/.local/share/eclipse/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t'),
--     },
-- }

-- local lvim_config = resolve_config('jdtls', config)
-- local server_available, jdtls = require('nvim-lsp-installer.servers').get_server('jdtls')

-- if server_available and jdtls:is_installed() then
--     jdtls:setup(lvim_config)
-- else
--     require('lspconfig')['jdtls'].setup(lvim_config)
-- end

-- local jar_patterns = {
--     home .. '/.local/src/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
--     home .. '/.local/src/vscode-java-test/server/*.jar',
-- }

-- local bundles = {}
-- for _, jar_pattern in ipairs(jar_patterns) do
--     for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
--         if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') then
--             table.insert(bundles, bundle)
--         end
--     end
-- end

-- local config = {
--     cmd = {
--         'jdtls.sh',
--         os.getenv('HOME') .. '/.local/share/eclipse/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t'),
--     },
--     init_options = {
--         bundles = bundles,
--     },
--     settings = {
--         java = {
--             signatureHelp = { enabled = true },
--             contentProvider = { preferred = 'fernflower' },
--             format = {
--                 settings = {
--                     url = 'file://' .. os.getenv('HOME') .. '/.eclipse-java-style.xml',
--                     profile = 'nexidia-rtig',
--                 },
--             },
--             codeGeneration = {
--                 toString = { template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}' },
--             },
--             configuration = {
--                 runtimes = {
--                     {
--                         name = 'JavaSE-11',
--                         path = os.getenv('HOME') .. '/.sdkman/candidates/java/11.0.11-zulu/',
--                         default = true,
--                     },
--                     { name = 'JavaSE-1.8', path = os.getenv('HOME') .. '/.sdkman/candidates/java/8.0.292-zulu' },
--                 },
--             },
--         },
--     },
-- }

-- require('jdtls').start_or_attach(config)
