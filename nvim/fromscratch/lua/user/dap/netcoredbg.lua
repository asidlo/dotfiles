local dap_ok, dap = pcall(require, 'dap')
if not dap_ok then
    return
end

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#Dotnet
dap.adapters.coreclr = {
    type = 'executable',
    command = 'netcoredbg',
    args = { '--interpreter=vscode' }
}

dap.configurations.cs = {
    {
        type = "coreclr",
        name = "launch - netcoredbg",
        request = "launch",
        program = function()
            return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end,
    },
}
