-- general
lvim.log.level = 'warn'
lvim.format_on_save = true
lvim.colorscheme = 'tokyonight'

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = 'space'
lvim.keys.normal_mode['<C-s>'] = ':w<cr>'
lvim.keys.insert_mode['<C-s>'] = '<Esc>:w<cr>'
lvim.keys.normal_mode['[<Space>'] = [[maO<Esc>`a]]
lvim.keys.normal_mode[']<Space>'] = [[mao<Esc>`a]]
lvim.keys.normal_mode['<F5>'] = '<Cmd>mode<cr>'
lvim.keys.normal_mode['<Leader>D'] = ':call v:lua.toggle_diagnostics()<CR>'
lvim.keys.normal_mode['<C-e>'] = '<Cmd>Telescope oldfiles<cr>'

lvim.keys.normal_mode['<S-l>'] = nil
lvim.keys.normal_mode['<S-h>'] = nil
lvim.keys.normal_mode[']b'] = '<Cmd>BufferNext<cr>'
lvim.keys.normal_mode['[b'] = '<Cmd>BufferPrevious<cr>'
lvim.keys.normal_mode[']p'] = ':call v:lua.paste_after()<cr>o'
lvim.keys.normal_mode['[p'] = ':call v:lua.paste_before()<cr>'

-- TODO (AS): Delay resetting opts since text isnt using the set paste
_G.paste_after = function()
    local paste_opt = vim.api.nvim_get_option('paste')
    local mouse_opt = vim.api.nvim_get_option('mouse')
    vim.api.nvim_set_option('paste', true)
    vim.api.nvim_set_option('mouse', '')

    local keys = vim.api.nvim_replace_termcodes('mao<C-r>*<Esc>`a', true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', true)

    vim.api.nvim_set_option('paste', paste_opt)
    vim.api.nvim_set_option('mouse', mouse_opt)
end
_G.paste_before = function()
    local paste_opt = vim.api.nvim_get_option('paste')
    local mouse_opt = vim.api.nvim_get_option('mouse')
    vim.api.nvim_set_option('paste', true)
    vim.api.nvim_set_option('mouse', '')

    local keys = vim.api.nvim_replace_termcodes('maO<C-r>*<Esc>`a', true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', true)
    vim.api.nvim_set_option('paste', paste_opt)

    vim.api.nvim_set_option('paste', paste_opt)
    vim.api.nvim_set_option('mouse', mouse_opt)
end

lvim.keys.normal_mode[']d'] =
    '<Cmd>lua vim.lsp.diagnostic.goto_next({popup_opts = {border = lvim.lsp.popup_border}})<CR>'
lvim.keys.normal_mode['[d'] =
    '<Cmd>lua vim.lsp.diagnostic.goto_prev({popup_opts = {border = lvim.lsp.popup_border}})<CR>'

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
lvim.builtin.telescope.on_config_done = function()
    local actions = require('telescope.actions')
    lvim.builtin.telescope.defaults.mappings.i['<C-j>'] = actions.move_selection_next
    lvim.builtin.telescope.defaults.mappings.i['<C-k>'] = actions.move_selection_previous
    lvim.builtin.telescope.defaults.mappings.i['<C-n>'] = actions.cycle_history_next
    lvim.builtin.telescope.defaults.mappings.i['<C-p>'] = actions.cycle_history_prev
    lvim.builtin.telescope.defaults.mappings.n['<C-j>'] = actions.move_selection_next
    lvim.builtin.telescope.defaults.mappings.n['<C-k>'] = actions.move_selection_previous
end

local cmp = require('cmp')
lvim.builtin.cmp.mapping['<CR>'].invoke = cmp.mapping.confirm({ select = true })

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

_G.tab_complete = function()
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

_G.s_tab_complete = function()
    if cmp and cmp.visible() then
        cmp.select_prev_item()
    elseif luasnip and luasnip.jumpable(-1) then
        luasnip.jump(-1)
    else
        return t('<S-Tab>')
    end
    return ''
end

vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.tab_complete()', { expr = true })
vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.tab_complete()', { expr = true })
vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
vim.api.nvim_set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })

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
    w = { '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'Diagnostics' },
    t = { '<cmd>TroubleToggle<cr>', 'Toggle Trouble' },
    R = { '<cmd>TroubleRefresh<cr>', 'Refresh Trouble' },
}
lvim.builtin.which_key.mappings['T'] = {
    name = '+Telescope',
    D = { '<Cmd>TodoTelescope<cr>', 'Todo' },
}
lvim.builtin.which_key.mappings['S'] = {
    name = '+Session',
    l = { '<Cmd>lua require("persistence").load({last=true})<cr>', 'Load last session' },
    c = { '<Cmd>lua require("persistence").load()<cr>', 'Load current session' },
    s = { '<Cmd>lua require("persistence").stop()<cr>', 'Stop current session' },
}

-- User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
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

lvim.lang.sh.linters = { { exe = 'shellcheck' } }
lvim.lang.sh.formatters = { { exe = 'shellharden' } }

lvim.lang.markdown.linters = {
    { exe = 'markdownlint', args = { '-c', os.getenv('HOME') .. '/.markdownlint.json' } },
    { exe = 'vale' },
}
lvim.lang.markdown.formatters = { { exe = 'prettierd' } }
lvim.lang.lua.linters = {
    {
        exe = 'luacheck',
        args = { '--globals', 'lvim', '--globals', 'vim' },
    },
}
lvim.lang.lua.formatters = {
    {
        exe = 'stylua',
        args = {
            '--indent-width',
            '4',
            '--quote-style',
            'AutoPreferSingle',
            '--indent-type',
            'Spaces',
        },
    },
}

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

lvim.lsp.on_attach_callback = function(client, bufnr)
    if client.resolved_capabilities.document_range_formatting then
        vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end
    require('lsp_signature').on_attach({
        toggle_key = '<C-q>',
    })
end

-- lvim.lsp.templates_dir = join_paths(get_config_dir(), 'after', 'ftplugin')

-- Additional Plugins
lvim.plugins = {
    { 'folke/tokyonight.nvim' },
    { 'tpope/vim-repeat' },
    { 'tpope/vim-surround', keys = { 'c', 'd', 'y' } },
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
        'folke/persistence.nvim',
        event = 'VimEnter',
        module = 'persistence',
        config = function()
            require('persistence').setup({
                dir = vim.fn.expand(vim.fn.stdpath('config') .. '/session/'),
                options = { 'buffers', 'curdir', 'tabpages', 'winsize' },
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
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
lvim.autocommands.custom_groups = {
    { 'TermOpen,TermEnter', 'term://*', 'startinsert!' },
    { 'TermEnter', 'term://*', 'setlocal nonumber norelativenumber signcolumn=no' },
}

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

lvim.lsp.override = { 'jdtls' }

_G.resize_tree = function()
    local nvim_tree_bufnr = require('nvim-tree.view').View.bufnr
    local nvim_win = vim.fn.win_findbuf(nvim_tree_bufnr)
    if next(nvim_win) then
        local tree_win = nvim_win[1]
        local tree_buf_width = vim.fn.winwidth(tree_win)
        require('bufferline.state').set_offset(tree_buf_width + 1, 'FileTree')
    else
        print('NvimTree buffer is hidden')
    end
end

lvim.keys.normal_mode['<Leader>r'] = '<Cmd>lua resize_tree()<cr>'
