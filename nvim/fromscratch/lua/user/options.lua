local options = {
    backup = false, -- creates a backup file
    writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
    clipboard = 'unnamedplus', -- allows neovim to access the system clipboard
    cmdheight = 2, -- more space in the neovim command line for displaying messages
    conceallevel = 0, -- so that `` is visible in markdown files
    fileencoding = 'utf-8', -- the encoding written to a file
    hlsearch = true, -- highlight all matches on previous search pattern
    ignorecase = true, -- ignore case in search patterns
    mouse = 'a', -- allow the mouse to be used in neovim
    pumheight = 10, -- pop up menu height
    showmode = false, -- we don't need to see things like -- INSERT -- anymore
    showtabline = 2, -- always show tabs
    smartcase = true, -- smart case
    smartindent = true, -- make indenting smarter again
    splitbelow = true, -- force all horizontal splits to go below current window
    splitright = true, -- force all vertical splits to go to the right of current window
    swapfile = false, -- creates a swapfile
    termguicolors = true, -- set term gui colors (most terminals support this)
    timeoutlen = 300, -- time to wait for a mapped sequence to complete (in milliseconds)
    undofile = true, -- enable persistent undo
    updatetime = 300, -- faster completion (4000ms default)
    expandtab = true, -- convert tabs to spaces
    shiftwidth = 4, -- the number of spaces inserted for each indentation
    tabstop = 4, -- insert 2 spaces for a tab
    cursorline = true, -- highlight the current line
    number = true, -- set numbered lines
    relativenumber = true, -- set relative numbered lines
    signcolumn = 'yes', -- always show the sign column, otherwise it would shift the text each time
    wrap = false, -- display lines as one long line
    scrolloff = 8, -- is one of my fav
    sidescrolloff = 8,
    wildmode = { 'longest:full', 'full' },
    completeopt = { 'menu', 'menuone', 'noselect' },
    foldenable = false,
    foldmethod = 'expr',
    foldexpr = 'nvim_treesitter#foldexpr()',
    autowriteall = true,
    modeline = false,
    modelines = 0,
    laststatus = 3,
}

vim.opt.shortmess:append('c')

local version = vim.version()
if version.major > 0 or version.minor >= 8 then
    vim.opt.winbar = "%{%v:lua.require('user.winbar').eval()%}"
end

if vim.fn.has('unix') == 1 then
    local home = os.getenv('HOME')
    vim.opt['dictionary'] = '/usr/share/dict/words'
    vim.opt['spellfile'] = home .. '/.config/nvim/spell/en.utf-8.add'
    vim.opt['thesaurus'] = home .. '/.config/nvim/spell/thesaurii.txt'
    if vim.fn.executable('zsh') == 1 then
        vim.opt['shell'] = 'zsh'
    end
else
    local home = os.getenv('USERPROFILE')
    vim.opt['dictionary'] = home .. '\\AppData\\Local\\nvim\\words'
    vim.opt['spellfile'] = home .. '\\AppData\\Local\\nvim\\spell\\en.utf-8.add'
    vim.opt['thesaurus'] = home .. '\\AppData\\Local\\nvim\\spell\\thesaurii.txt'
end

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

if vim.fn.has('win32') == 1 then
    vim.g.python3_host_prog = '~\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe'
else
    vim.g.python3_host_prog = '/usr/bin/python3'
end

local default_plugins = {
   "2html_plugin",
   "getscript",
   "getscriptPlugin",
   -- "gzip",
   "logipat",
   "netrw",
   "netrwPlugin",
   "netrwSettings",
   "netrwFileHandlers",
   "matchit",
   -- "tar",
   -- "tarPlugin",
   "rrhelper",
   "spellfile_plugin",
   "vimball",
   "vimballPlugin",
   -- "zip",
   -- "zipPlugin",
}

for _, plugin in pairs(default_plugins) do
   vim.g["loaded_" .. plugin] = 1
end

if vim.fn.executable('rg') then
    vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
    vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- https://jdhao.github.io/2020/03/14/nvim_search_replace_multiple_file/
-- https://stackoverflow.com/a/51962260
-- https://thoughtbot.com/blog/faster-grepping-in-vim
vim.cmd('packadd cfilter')

vim.cmd('iab tdate <c-r>=strftime("%Y/%m/%d %H:%M:%S")<cr>')
vim.cmd('iab ddate <c-r>=strftime("%Y-%m-%d")<cr>')
vim.cmd('cab ddate <c-r>=strftime("%Y_%m_%d")<cr>')
vim.cmd('iab sdate <c-r>=strftime("%A %B %d, %Y")<cr>')
