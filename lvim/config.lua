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
vim.opt.dictionary = '/usr/share/dict/words' -- wamerican-insane <C-X, C-S>
vim.opt.thesaurus = '~/.config/lvim/spell/thesaurii.txt' -- <C-X, C-T>
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
lvim.builtin.terminal.active = true
lvim.builtin.dap.active = true
lvim.builtin.nvimtree.setup.view.side = 'left'
lvim.builtin.nvimtree.show_icons.tree_width = 40
lvim.builtin.nvimtree.show_icons.git = 0
lvim.builtin.nvimtree.setup.view.auto_resize = false
lvim.builtin.nvimtree.setup.view.nvim_tree_group_empty = 1
lvim.builtin.nvimtree.nvim_tree_gitignore = 1
lvim.builtin.nvimtree.setup.filters = { '.git', 'node_modules', '.cache', '.DS_Store' }
lvim.builtin.lualine.style = 'default'

vim.list_extend(lvim.lsp.override, { 'jdtls' })
lvim.lsp.automatic_servers_installation = false
lvim.lsp.on_attach_callback = function(client, bufnr)
    if client.resolved_capabilities.document_range_formatting then
        vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.lsp_formatexpr()')
    end
end

lvim.builtin.treesitter.ensure_installed = {
    'bash',
    'c',
    'cpp',
    'cmake',
    'c_sharp',
    'vue',
    'javascript',
    'json',
    'jsonc',
    'json5',
    'html',
    'lua',
    'python',
    'typescript',
    'css',
    'rust',
    'kotlin',
    'java',
    'vim',
    'yaml',
    'toml',
    'rst',
    'gomod',
    'go',
    'dockerfile',
}
lvim.builtin.treesitter.highlight.enabled = true
lvim.builtin.treesitter.incremental_selection = {
    enable = true,
    keymaps = {
        init_selection = '<CR>',
        scope_incremental = '<CR>',
        node_incremental = '<TAB>',
        node_decremental = '<S-TAB>',
    },
}
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

lvim.keys.insert_mode['<Tab>'] = { 'v:lua.tab_complete()', { expr = true } }
lvim.keys.insert_mode['<S-Tab>'] = { 'v:lua.s_tab_complete()', { expr = true } }
lvim.keys.insert_mode['<C-s>'] = '<Esc>:w<cr>'

lvim.keys.normal_mode['<S-l>'] = false
lvim.keys.normal_mode['<S-h>'] = false
lvim.keys.normal_mode['<C-s>'] = ':w<cr><Esc>'
lvim.keys.normal_mode['<F5>'] = '<Cmd>mode<cr>'
lvim.keys.normal_mode['<Tab>'] = { 'v:lua.tab_complete()', { expr = true } }
lvim.keys.normal_mode['<S-Tab>'] = { 'v:lua.s_tab_complete()', { expr = true } }

lvim.builtin.which_key.mappings['lD'] = { ':call v:lua.toggle_diagnostics()<CR>', 'Toggle Diagnostics' }
lvim.builtin.which_key.mappings['sp'] = { '<Cmd>Telescope projects<CR>', 'Search Projects' }
lvim.builtin.which_key.mappings['lo'] = { '<Cmd>SymbolsOutline<CR>', 'Symbols Outline' }

-- Additional Plugins
lvim.plugins = {
    { 'tpope/vim-repeat' },
    { 'tpope/vim-surround', keys = { 'c', 'd', 'y' } },
    { 'tpope/vim-unimpaired', keys = { '[', ']', 'y' } },
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
    { 'folke/tokyonight.nvim' },
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
    { 'mfussenegger/nvim-jdtls' },
    { 'simrat39/symbols-outline.nvim', cmd = 'SymbolsOutline' },
    { 'nvim-treesitter/nvim-treesitter-textobjects' },
    {
        'nvim-telescope/telescope-project.nvim',
        event = 'BufWinEnter',
        setup = function()
            vim.cmd([[packadd telescope.nvim]])
        end,
    },
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
    { 'segeljakt/vim-silicon' },
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
