return {
    -- cmd = {
    --     'dotnet',
    --     -- '/home/asidlo/.local/share/nvim/lsp_servers/omnisharp/omnisharp/OmniSharp.dll',
    --     '/home/asidlo/omnisharp6/OmniSharp.dll',
    --     '--languageserver',
    --     '-z',
    --     -- '-s',
    --     -- '/home/asidlo/workspace/src/msft/Networking-AppGW/src/ApplicationGatewayCpp.sln',
    --     '--hostPID',
    --     tostring(vim.fn.getpid()),
    --     '--loglevel',
    --     'information',
    -- },
    handlers = {
        ['textDocument/definition'] = require('omnisharp_extended').handler,
    },
}
