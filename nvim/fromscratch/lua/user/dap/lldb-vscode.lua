local dap_ok, dap = pcall(require, 'dap')
if not dap_ok then
    return
end

local exe = '/usr/bin/lldb-vscode'
if vim.fn.has('win32') == 1 then
    exe = 'C:\\Program Files\\LLVM\\bin\\lldb-vscode.exe'
else
    exe = '/usr/local/bin/lldb-vscode'
end

dap.adapters.lldb = {
    type = 'executable',
    command = exe,
    name = 'lldb',
}

dap.configurations.cpp = {
    {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},

        -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
        --
        --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
        --
        -- Otherwise you might get the following error:
        --
        --    Error on launch: Failed to attach to the target process
        --
        -- But you should be aware of the implications:
        -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
        runInTerminal = true,
    },
}

-- If you want to use this for rust and c, add something like this:

dap.configurations.c = dap.configurations.cpp
-- dap.configurations.rust = dap.configurations.cpp
-- dap.configurations.rust = dap.configurations.cpp
