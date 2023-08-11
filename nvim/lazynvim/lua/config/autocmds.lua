-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local settings = augroup("user_settings", { clear = true })

autocmd({ "TermOpen", "TermEnter" }, {
  group = settings,
  pattern = "term://*",
  desc = "Start terminal in insert mode",
  callback = function()
    vim.cmd("startinsert!")
  end,
})

autocmd({ "TermEnter" }, {
  group = settings,
  pattern = "term://*",
  desc = "Change terminal settings",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
