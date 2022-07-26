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
        name = ".NET Core Attach",
        type = "coreclr",
        request = "attach",
        processId = "${command:pickProcess}"
    },
    {
        name = ".NET Core Launch (console)",
        type = "coreclr",
        request = "launch",
        cwd = function ()
            return vim.fn.input('Path to cwd', vim.fn.getcwd(), 'file')
        end,
        program = function()
            return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end,
        console = 'internalConsole',
        stopAtEntry = false
    },
    {
        type = "coreclr",
        name = ".NET Core Attach",
        request = 'attach',
        processId = '${command:pickProcess}'
    }
}
