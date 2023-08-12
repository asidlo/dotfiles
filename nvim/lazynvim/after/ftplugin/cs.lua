vim.g["test#csharp#runner"] = "dotnettest"
vim.g["test#strategy"] = "neovim"
vim.g["test#csharp#dotnettest#options"] = {
  all = '-l "console;verbosity=detailed"',
}
vim.cmd("setlocal noexpandtab tabstop=4 shiftwidth=4")
