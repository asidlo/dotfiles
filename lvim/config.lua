vim.opt.showtabline = 0
vim.opt.relativenumber = true
vim.opt.wildmode = { 'longest:full', 'full' }
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.timeoutlen = 300
vim.opt.foldenable = false
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
-- vim.opt.formatexpr = 'v:lua.lsp_formatexpr()'
vim.g.loaded_python_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.markdown_fenced_languages = {
    'bash',
    'json',
    'javascript',
    'python',
    'java',
    'groovy',
    'go',
    'rust',
}

if vim.fn.executable('rg') then
    vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
    vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- https://jdhao.github.io/2020/03/14/nvim_search_replace_multiple_file/
-- https://stackoverflow.com/a/51962260
-- https://thoughtbot.com/blog/faster-grepping-in-vim
vim.cmd('packadd cfilter')

-- general
lvim.log.level = 'warn'
lvim.format_on_save = true
lvim.colorscheme = 'tokyonight'
lvim.leader = 'space'

-- User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.bufferline.active = false
lvim.builtin.dap.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = 'left'
lvim.builtin.nvimtree.show_icons.tree_width = 40
lvim.builtin.nvimtree.show_icons.git = 0
lvim.builtin.nvimtree.setup.view.auto_resize = false
lvim.builtin.nvimtree.setup.view.nvim_tree_group_empty = 1
lvim.builtin.nvimtree.nvim_tree_gitignore = 1
lvim.builtin.nvimtree.ignore = { '.git', 'node_modules', '.cache', '.DS_Store' }
lvim.builtin.lualine.style = 'default'
lvim.builtin.treesitter.ensure_installed = {
    'bash',
    'c',
    'javascript',
    'json',
    'lua',
    'python',
    'typescript',
    'css',
    'rust',
    'java',
    'yaml',
}
vim.list_extend(lvim.lsp.override, { 'jdtls' })
lvim.lsp.automatic_servers_installation = false
lvim.lsp.on_attach_callback = function(client, bufnr)
    if client.resolved_capabilities.document_range_formatting then
        vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end
end

lvim.builtin.treesitter.ignore_install = { 'haskell' }
lvim.builtin.treesitter.highlight.enabled = true
lvim.builtin.treesitter.textobjects = {
    select = {
        enable = true,
        keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
        },
    },
    move = {
        enable = true,
        goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.outer' },
        goto_next_end = { [']M'] = '@function.outer', [']['] = '@class.outer' },
        goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.outer' },
        goto_previous_end = { ['[M'] = '@function.outer', ['[]'] = '@class.outer' },
    },
    swap = {
        enable = false,
    },
}
lvim.builtin.treesitter.indent = {
    enable = true,
    disable = { 'yaml', 'json', 'java' },
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
lvim.autocommands.custom_groups = {
    { 'TermOpen,TermEnter', 'term://*', 'startinsert!' },
    { 'TermEnter', 'term://*', 'setlocal nonumber norelativenumber signcolumn=no' },
}

lvim.keys.insert_mode = {
    ['<A-Down>'] = '<C-\\><C-N><C-w>j',
    ['<A-Left>'] = '<C-\\><C-N><C-w>h',
    ['<A-Right>'] = '<C-\\><C-N><C-w>l',
    ['<A-Up>'] = '<C-\\><C-N><C-w>k',
    ['<A-j>'] = '<Esc>:m .+1<CR>==gi',
    ['<A-k>'] = '<Esc>:m .-2<CR>==gi',
    ['<C-s>'] = '<Esc>:w<cr>',
    ['<Tab>'] = { 'v:lua.tab_complete()', { expr = true } },
    ['<S-Tab>'] = { 'v:lua.s_tab_complete()', { expr = true } },
}
lvim.keys.normal_mode = {
    ['<A-j>'] = ':m .+1<CR>==',
    ['<A-k>'] = ':m .-2<CR>==',
    ['<C-Down>'] = ':resize +2<CR>',
    ['<C-Left>'] = ':vertical resize -2<CR>',
    ['<C-Right>'] = ':vertical resize +2<CR>',
    ['<C-Up>'] = ':resize -2<CR>',
    ['<C-e>'] = '<Cmd>Telescope oldfiles<cr>',
    ['<C-h>'] = '<C-w>h',
    ['<C-j>'] = '<C-w>j',
    ['<C-k>'] = '<C-w>k',
    ['<C-l>'] = '<C-w>l',
    ['<C-q>'] = ':call QuickFixToggle()<CR>',
    ['<C-s>'] = ':w<cr>',
    ['<F5>'] = '<Cmd>mode<cr>',
    ['<Leader>D'] = ':call v:lua.toggle_diagnostics()<CR>',
    ['<Leader>dU'] = '<Cmd>lua require("dapui").toggle()<CR>',
    ['<Leader>dvh'] = '<Cmd>lua require("dap.ui.variables").hover()<CR>',
    ['<Leader>dvs'] = '<Cmd>lua require("dap.ui.variables").scopes()<CR>',
    ['[d'] = '<Cmd>lua vim.lsp.diagnostic.goto_prev({popup_opts = {border = lvim.lsp.popup_border}})<CR>',
    ['[q'] = ':cprev<CR>',
    [']d'] = '<Cmd>lua vim.lsp.diagnostic.goto_next({popup_opts = {border = lvim.lsp.popup_border}})<CR>',
    [']q'] = ':cnext<CR>',
    ['<Tab>'] = { 'v:lua.tab_complete()', { expr = true } },
    ['<S-Tab>'] = { 'v:lua.s_tab_complete()', { expr = true } },
}
lvim.keys.term_mode = {
    ['<C-h>'] = '<C-\\><C-N><C-w>h',
    ['<C-j>'] = '<C-\\><C-N><C-w>j',
    ['<C-k>'] = '<C-\\><C-N><C-w>k',
    ['<C-l>'] = '<C-\\><C-N><C-w>l',
}
lvim.keys.visual_block_mode = {
    ['<A-j>'] = ":m '>+1<CR>gv-gv",
    ['<A-k>'] = ":m '<-2<CR>gv-gv",
    J = ":move '>+1<CR>gv-gv",
    K = ":move '<-2<CR>gv-gv",
}
lvim.keys.visual_mode = {
    ['<'] = '<gv',
    ['<Leader>dvh'] = '<Cmd>lua require("dap.ui.variables").visual_hover()<CR>',
    ['<Leader>dwf'] = '<Cmd>lua widgets=require("dap.ui.widgets"); widgets.centered_float(widgets.scopes)<CR>',
    ['<Leader>dwh'] = '<Cmd>lua require("dap.ui.widgets").hover()<CR>',
    ['>'] = '>gv',
}

lvim.builtin.which_key.mappings = {
    ['f'] = { '<cmd>Telescope find_files<CR>', 'Find File' },
    ['h'] = { '<cmd>nohlsearch<CR>', 'No Highlight' },
    b = {
        name = 'Buffers',
        j = { '<cmd>BufferPick<cr>', 'Jump' },
        f = { '<cmd>Telescope buffers<cr>', 'Find' },
        b = { '<cmd>b#<cr>', 'Previous' },
        w = { '<cmd>BufferWipeout<cr>', 'Wipeout' },
        e = {
            '<cmd>BufferCloseAllButCurrent<cr>',
            'Close all but current',
        },
    },
    g = {
        name = 'Git',
        j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", 'Next Hunk' },
        k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", 'Prev Hunk' },
        l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", 'Blame' },
        p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", 'Preview Hunk' },
        r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", 'Reset Hunk' },
        R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", 'Reset Buffer' },
        s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", 'Stage Hunk' },
        u = {
            "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
            'Undo Stage Hunk',
        },
        o = { '<cmd>Telescope git_status<cr>', 'Open changed file' },
        b = { '<cmd>Telescope git_branches<cr>', 'Checkout branch' },
        c = { '<cmd>Telescope git_commits<cr>', 'Checkout commit' },
        C = {
            '<cmd>Telescope git_bcommits<cr>',
            'Checkout commit(for current file)',
        },
        d = {
            '<cmd>Gitsigns diffthis HEAD<cr>',
            'Git Diff',
        },
    },

    l = {
        name = 'LSP',
        a = { "<cmd>lua require('lvim.core.telescope').code_actions()<cr>", 'Code Action' },
        d = {
            '<cmd>Telescope lsp_document_diagnostics<cr>',
            'Document Diagnostics',
        },
        w = {
            '<cmd>Telescope lsp_workspace_diagnostics<cr>',
            'Workspace Diagnostics',
        },
        f = { '<cmd>lua vim.lsp.buf.formatting()<cr>', 'Format' },
        i = { '<cmd>LspInfo<cr>', 'Info' },
        I = { '<cmd>LspInstallInfo<cr>', 'Installer Info' },
        j = {
            '<cmd>lua vim.lsp.diagnostic.goto_next({popup_opts = {border = lvim.lsp.popup_border}})<cr>',
            'Next Diagnostic',
        },
        k = {
            '<cmd>lua vim.lsp.diagnostic.goto_prev({popup_opts = {border = lvim.lsp.popup_border}})<cr>',
            'Prev Diagnostic',
        },
        l = { '<cmd>lua vim.lsp.codelens.run()<cr>', 'CodeLens Action' },
        p = {
            name = 'Peek',
            d = { "<cmd>lua require('lvim.lsp.peek').Peek('definition')<cr>", 'Definition' },
            t = { "<cmd>lua require('lvim.lsp.peek').Peek('typeDefinition')<cr>", 'Type Definition' },
            i = { "<cmd>lua require('lvim.lsp.peek').Peek('implementation')<cr>", 'Implementation' },
        },
        q = { '<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>', 'Quickfix' },
        r = { '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename' },
        s = { '<cmd>Telescope lsp_document_symbols<cr>', 'Document Symbols' },
        S = {
            '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>',
            'Workspace Symbols',
        },
    },
    L = {
        name = '+LunarVim',
        c = {
            '<cmd>edit ' .. get_config_dir() .. '/config.lua<cr>',
            'Edit config.lua',
        },
        f = {
            "<cmd>lua require('lvim.core.telescope.custom-finders').find_lunarvim_files()<cr>",
            'Find LunarVim files',
        },
        g = {
            "<cmd>lua require('lvim.core.telescope.custom-finders').grep_lunarvim_files()<cr>",
            'Grep LunarVim files',
        },
        k = { "<cmd>lua require('lvim.keymappings').print()<cr>", "View LunarVim's default keymappings" },
        i = {
            "<cmd>lua require('lvim.core.info').toggle_popup(vim.bo.filetype)<cr>",
            'Toggle LunarVim Info',
        },
        I = {
            "<cmd>lua require('lvim.core.telescope.custom-finders').view_lunarvim_changelog()<cr>",
            "View LunarVim's changelog",
        },
        l = {
            name = '+logs',
            d = {
                "<cmd>lua require('lvim.core.terminal').toggle_log_view(require('lvim.core.log').get_path())<cr>",
                'view default log',
            },
            D = {
                "<cmd>lua vim.fn.execute('edit ' .. require('lvim.core.log').get_path())<cr>",
                'Open the default logfile',
            },
            l = {
                "<cmd>lua require('lvim.core.terminal').toggle_log_view(vim.lsp.get_log_path())<cr>",
                'view lsp log',
            },
            L = { "<cmd>lua vim.fn.execute('edit ' .. vim.lsp.get_log_path())<cr>", 'Open the LSP logfile' },
            n = {
                "<cmd>lua require('lvim.core.terminal').toggle_log_view(os.getenv('NVIM_LOG_FILE'))<cr>",
                'view neovim log',
            },
            N = { '<cmd>edit $NVIM_LOG_FILE<cr>', 'Open the Neovim logfile' },
            p = {
                "<cmd>lua require('lvim.core.terminal').toggle_log_view('packer.nvim')<cr>",
                'view packer log',
            },
            P = { "<cmd>exe 'edit '.stdpath('cache').'/packer.nvim.log'<cr>", 'Open the Packer logfile' },
        },
        r = { '<cmd>LvimReload<cr>', "Reload LunarVim's configuration" },
        u = { '<cmd>LvimUpdate<cr>', 'Update LunarVim' },
    },
    s = {
        name = 'Search',
        b = { '<cmd>Telescope git_branches<cr>', 'Checkout branch' },
        c = { '<cmd>Telescope colorscheme<cr>', 'Colorscheme' },
        f = { '<cmd>Telescope find_files<cr>', 'Find File' },
        h = { '<cmd>Telescope help_tags<cr>', 'Find Help' },
        m = { '<cmd>Telescope man_pages<cr>', 'Man Pages' },
        r = { '<cmd>Telescope oldfiles<cr>', 'Open Recent File' },
        ['@'] = { '<cmd>Telescope registers<cr>', 'Registers' },
        t = { '<cmd>Telescope live_grep<cr>', 'Text' },
        k = { '<cmd>Telescope keymaps<cr>', 'Keymaps' },
        x = { '<cmd>Telescope commands<cr>', 'Commands' },
        p = {
            "<cmd>lua require('telescope.builtin.internal').colorscheme({enable_preview = true})<cr>",
            'Colorscheme with Preview',
        },
    },
}
lvim.keys.normal_mode['<Leader>dvs'] = '<Cmd>lua require("dap.ui.variables").scopes()<CR>'
lvim.keys.normal_mode['<Leader>dvh'] = '<Cmd>lua require("dap.ui.variables").hover()<CR>'
lvim.keys.visual_mode['<Leader>dvh'] = '<Cmd>lua require("dap.ui.variables").visual_hover()<CR>'
lvim.keys.visual_mode['<Leader>dwh'] = '<Cmd>lua require("dap.ui.widgets").hover()<CR>'
lvim.keys.visual_mode['<Leader>dwf'] =
    '<Cmd>lua widgets=require("dap.ui.widgets"); widgets.centered_float(widgets.scopes)<CR>'
lvim.keys.normal_mode['<Leader>dU'] = '<Cmd>lua require("dapui").toggle()<CR>'

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings['P'] = {
    '<cmd>Telescope projects<CR>',
    'Projects',
}
lvim.builtin.which_key.mappings['t'] = {
    name = '+Trouble',
    r = { '<cmd>Trouble lsp_references<cr>', 'References' },
    f = { '<cmd>Trouble lsp_definitions<cr>', 'Definitions' },
    d = { '<cmd>Trouble lsp_document_diagnostics<cr>', 'Diagnostics' },
    q = { '<cmd>Trouble quickfix<cr>', 'QuickFix' },
    l = { '<cmd>Trouble loclist<cr>', 'LocationList' },
    D = { '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'Diagnostics' },
    t = { '<cmd>TroubleToggle<cr>', 'Toggle Trouble' },
    R = { '<cmd>TroubleRefresh<cr>', 'Refresh Trouble' },
}
lvim.builtin.which_key.mappings['T'] = {
    name = '+Telescope',
    D = { '<Cmd>TodoTelescope<cr>', 'Todo' },
}

-- Additional Plugins
lvim.plugins = {
    { 'folke/tokyonight.nvim' },
    { 'tpope/vim-repeat' },
    { 'tpope/vim-surround', keys = { 'c', 'd', 'y' } },
    { 'tpope/vim-unimpaired', keys = { '[', ']' } },
    { 'tpope/vim-obsession', cmd = { 'Obsess', 'Obsess!' } },
    {
        'tpope/vim-fugitive',
        cmd = {
            'G',
            'Git',
            'Gdiffsplit',
            'Gread',
            'Gwrite',
            'Ggrep',
            'GMove',
            'GDelete',
            'GBrowse',
            'GRemove',
            'GRename',
            'Glgrep',
            'Gedit',
        },
        ft = { 'fugitive' },
    },
    {
        'folke/todo-comments.nvim',
        event = 'BufRead',
        config = function()
            require('todo-comments').setup({
                highlight = {
                    keyword = 'wide',
                    pattern = [[.*<(KEYWORDS) (\([^\)]*\))?:]],
                },
                search = { pattern = [[\b(KEYWORDS) (\([^\)]*\))?:]] },
            })
        end,
    },
    { 'folke/trouble.nvim', cmd = 'TroubleToggle' },
    {
        'lukas-reineke/indent-blankline.nvim',
        event = 'BufRead',
        setup = function()
            vim.g.indentLine_enabled = 1
            vim.g.indent_blankline_char = '▏'
            vim.g.indent_blankline_filetype_exclude = {
                'help',
                'terminal',
                'dashboard',
                'packer',
                'lsp-installer',
                'lspinfo',
            }
            vim.g.indent_blankline_buftype_exclude = { 'terminal' }
            vim.g.indent_blankline_show_trailing_blankline_indent = false
            vim.g.indent_blankline_show_first_indent_level = false
            vim.g.indent_blankline_use_treesitter = true
        end,
    },
    { 'simrat39/symbols-outline.nvim', cmd = 'SymbolsOutline' },
    {
        'nvim-telescope/telescope-project.nvim',
        event = 'BufWinEnter',
        setup = function()
            vim.cmd([[packadd telescope.nvim]])
        end,
    },
    { 'segeljakt/vim-silicon' },
    {
        'ethanholz/nvim-lastplace',
        event = 'BufRead',
        config = function()
            require('nvim-lastplace').setup({
                lastplace_ignore_buftype = { 'quickfix', 'nofile', 'help' },
                lastplace_ignore_filetype = {
                    'gitcommit',
                    'gitrebase',
                    'svn',
                    'hgcommit',
                },
                lastplace_open_folds = true,
            })
        end,
    },
    {
        'aymericbeaumet/vim-symlink',
        event = 'BufRead',
        requires = {
            { 'moll/vim-bbye' },
        },
    },
    { 'mfussenegger/nvim-jdtls' },
    { 'ray-x/lsp_signature.nvim' },
    { 'nvim-treesitter/nvim-treesitter-textobjects' },
    {
        'nvim-telescope/telescope-dap.nvim',
        event = 'BufWinEnter',
        setup = function()
            vim.cmd([[packadd telescope.nvim]])
        end,
        config = function()
            require('telescope').load_extension('dap')
        end,
    },
    {
        'theHamsta/nvim-dap-virtual-text',
        config = function()
            require('nvim-dap-virtual-text').setup()
        end,
    },
    {
        'rcarriga/nvim-dap-ui',
        config = function()
            require('dapui').setup()
        end,
    },
}

local cmp = require('cmp')
lvim.builtin.cmp.mapping['<CR>'] = cmp.mapping.confirm({ select = true })

local luasnip = require('luasnip')

local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

function _G.tab_complete()
    if cmp and cmp.visible() then
        cmp.select_next_item()
    elseif luasnip and luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
    elseif check_back_space() then
        return t('<Tab>')
    else
        cmp.complete()
    end
    return ''
end

function _G.s_tab_complete()
    if cmp and cmp.visible() then
        cmp.select_prev_item()
    elseif luasnip and luasnip.jumpable(-1) then
        luasnip.jump(-1)
    else
        return t('<S-Tab>')
    end
    return ''
end

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, { ... })
    print(unpack(objects))
end

function _G.new_buf(...)
    local objects = vim.tbl_map(vim.inspect, { ... })
    local buf = vim.api.nvim_create_buf(true, true)
    local content = {}
    for _, obj in ipairs(objects) do
        for _, line in ipairs(vim.split(obj, '\n')) do
            table.insert(content, line)
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)
    vim.cmd('b ' .. buf)
end

-- Until they release the `vim.lsp.util.formatexpr()`
-- https://github.com/neovim/neovim/issues/12528
-- https://github.com/neovim/neovim/pull/12547
-- https://github.com/neovim/neovim/pull/13138
--
--- Implements an LSP `formatexpr`-compatible
-- @param start_line 1-indexed line, defaults to |v:lnum|
-- @param end_line 1-indexed line, calculated based on {start_line} and |v:count|
-- @param timeout_ms optional, defaults to 500ms
function _G.lsp_formatexpr(start_line, end_line, timeout_ms)
    timeout_ms = timeout_ms or 500

    if not start_line or not end_line then
        if vim.fn.mode() == 'i' or vim.fn.mode() == 'R' then
            -- `formatexpr` is also called when exceeding `textwidth` in insert mode
            -- fall back to internal formatting
            return 1
        end
        start_line = vim.v.lnum
        end_line = start_line + vim.v.count - 1
    end

    if start_line > 0 and end_line > 0 then
        local end_char = vim.fn.col('$')
        vim.lsp.buf.range_formatting({}, { start_line, 0 }, { end_line, end_char })
    end

    -- do not run builtin formatter after lsp format
    return 0
end

-- https://github.com/neovim/neovim/issues/14825
vim.g.diagnostics_visible = true

function _G.toggle_diagnostics()
    if vim.g.diagnostics_visible then
        vim.g.diagnostics_visible = false
        vim.lsp.diagnostic.clear(0)
        vim.lsp.handlers['textDocument/publishDiagnostics'] = function() end
        print('Diagnostics are hidden')
    else
        vim.g.diagnostics_visible = true
        vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            virtual_text = true,
            signs = true,
            underline = true,
            update_in_insert = false,
        })
        vim.cmd('e ' .. vim.fn.expand('%'))
        print('Diagnostics are visible')
    end
end

-- Map K to hover while session is active
local dap = require('dap')
local api = vim.api
local keymap_restore = {}
dap.listeners.after['event_initialized']['me'] = function()
    for _, buf in pairs(api.nvim_list_bufs()) do
        local keymaps = api.nvim_buf_get_keymap(buf, 'n')
        for _, keymap in pairs(keymaps) do
            if keymap.lhs == 'K' then
                table.insert(keymap_restore, keymap)
                api.nvim_buf_del_keymap(buf, 'n', 'K')
            end
        end
    end
    api.nvim_set_keymap('n', 'K', '<Cmd>lua require("dap.ui.variables").hover()<CR>', { silent = true })
end

dap.listeners.after['event_terminated']['me'] = function()
    for _, keymap in pairs(keymap_restore) do
        api.nvim_buf_set_keymap(keymap.buffer, keymap.mode, keymap.lhs, keymap.rhs, { silent = keymap.silent == 1 })
    end
    keymap_restore = {}
end

require('lsp_signature').setup({
    toggle_key = '<M-q>',
})
