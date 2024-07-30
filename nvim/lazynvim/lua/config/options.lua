-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.autoformat = false

if vim.loop.os_uname().sysname == "Windows_NT" then
  if string.match(vim.fn.system("uname"), "MINGW64*") then
    vim.cmd([[
      let &shell='bash.exe'
      let &shellcmdflag = '-c'
      let &shellredir = '>%s 2>&1'
      set shellquote= shellxescape=
      " set noshelltemp
      set shellxquote=
      let &shellpipe='2>&1| tee'
      let $TMP="/tmp"
   ]])
  else
    vim.cmd([[
      let &shell = executable('pwsh') ? 'pwsh' : 'powershell'
      let &shellcmdflag = '-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues[''Out-File:Encoding'']=''utf8'';Remove-Alias -Force -ErrorAction SilentlyContinue tee;'
      let &shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
      let &shellpipe  = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
      set shellquote= shellxquote=
      ]])
  end
end
