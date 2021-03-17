vim.o.splitbelow = true
vim.o.splitright = true
vim.o.termguicolors = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.smartcase = true
vim.o.showmode = false
vim.o.hidden = true
vim.o.autoread = true
vim.o.autowriteall = true
vim.o.mouse = 'a'
vim.o.completeopt = 'menuone,noselect'
vim.o.clipboard = 'unnamed'
vim.o.wildmode = 'longest:full,full'
vim.o.updatetime = 300
vim.o.cmdheight = 2
vim.o.shortmess = vim.o.shortmess..'c'
vim.o.wildignore = '*.o,*~,*.pyc,*.class,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store'

vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'

vim.o.swapfile = false
vim.bo.swapfile = false
vim.o.undofile = true
vim.bo.undofile = true
vim.o.modeline = false
vim.bo.modeline = false
vim.o.expandtab = true
vim.bo.expandtab = true
vim.o.smartindent = true
vim.bo.smartindent = true
vim.o.textwidth = 119
vim.bo.textwidth = 119
vim.o.shiftwidth = 4
vim.bo.shiftwidth = 4
vim.o.tabstop = 4
vim.bo.tabstop = 4

vim.wo.wrap = false
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.foldenable = false
vim.wo.signcolumn = 'yes'

vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.colors_name = 'dracula'
vim.g.python3_host_prog = '/usr/bin/python3'

vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.did_install_default_menus = 1
vim.g.did_install_syntax_menu = 1

vim.g.mapleader = ','
