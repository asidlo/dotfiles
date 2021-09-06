local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.sn
local t = ls.text_node
local i = ls.insert_node
local c = ls.c
local d = ls.d
local types = require("luasnip.util.types")

-- ls.config.set_config({history = true, updateevents = "TextChanged,TextChangedI"})
ls.config.setup({
    history = true,
    updateevents = 'InsertLeave',
    enable_autosnippets = true,
    region_check_events = "CursorHold",
    delete_check_events = "TextChanged",
    store_selection_keys = "<Tab>",
    ext_opts = {
        [types.choiceNode] = {
            active = {
                virt_text = {{"●", "DraculaOrange"}},
            }
        },
        [types.insertNode] = {
            active = {
                virt_text = {{"●", "DraculaCyan"}},
            }
        },
    },
})

local function char_count_same(c1, c2)
	local line = vim.api.nvim_get_current_line()
	local _, ct1 = string.gsub(line, '%'..c1, '')
	local _, ct2 = string.gsub(line, '%'..c2, '')
	return ct1 == ct2
end

local function even_count(pattern)
    local line = vim.api.nvim_get_current_line()
    local _, ct = string.gsub(line, pattern, '')
    return ct % 2 == 0
end

local function neg(fn, ...) return not fn(...) end

local function jdocsnip(args, old_state)
    local nodes = {t({"/**", " * "}), i(1, {"A short Description"}), t({"", ""})}

    -- These will be merged with the snippet; that way, should the snippet be updated,
    -- some user input eg. text can be referred to in the new snippet.
    local param_nodes = {}

    if old_state then nodes[2] = i(1, old_state.descr:get_text()) end
    param_nodes.descr = nodes[2]

    -- At least one param.
    if string.find(args[2][1], ", ") then vim.list_extend(nodes, {t({" * ", ""})}) end

    local insert = 2
    for _, arg in ipairs(vim.split(args[2][1], ", ", true)) do
        -- Get actual name parameter.
        arg = vim.split(arg, " ", true)[2]
        if arg then
            local inode
            -- if there was some text in this parameter, use it as static_text for this new snippet.
            if old_state and old_state["arg" .. arg] then
                inode = i(insert, old_state["arg" .. arg]:get_text())
            else
                inode = i(insert)
            end
            vim.list_extend(nodes, {t({" * @param " .. arg .. " "}), inode, t({"", ""})})
            param_nodes["arg" .. arg] = inode

            insert = insert + 1
        end
    end

    if args[1][1] ~= "void" then
        local inode
        if old_state and old_state.ret then
            inode = i(insert, old_state.ret:get_text())
        else
            inode = i(insert)
        end

        vim.list_extend(nodes, {t({" * ", " * @return "}), inode, t({"", ""})})
        param_nodes.ret = inode
        insert = insert + 1
    end

    if vim.tbl_count(args[3]) ~= 1 then
        local exc = string.gsub(args[3][2], " throws ", "")
        local ins
        if old_state and old_state.ex then
            ins = i(insert, old_state.ex:get_text())
        else
            ins = i(insert)
        end
        vim.list_extend(nodes, {t({" * ", " * @throws " .. exc .. " "}), ins, t({"", ""})})
        param_nodes.ex = ins
        insert = insert + 1
    end

    vim.list_extend(nodes, {t({" */"})})

    local snip = sn(nil, nodes)
    -- Error on attempting overwrite.
    snip.old_state = param_nodes
    return snip
end

local function part(func, ...)
    local args = {...}
    return function() return func(unpack(args)) end
end

local function pair(pair_begin, pair_end, expand_func, ...)
    return s({trig = pair_begin, wordTrig = false}, {t({pair_begin}), i(1), t({pair_end})},
             {condition = part(expand_func, part(..., pair_begin, pair_end))})
end

-- LuaFormatter off
ls.snippets = {
    all = {
        pair("(", ")", neg, char_count_same),
        pair("{", "}", neg, char_count_same),
        pair("[", "]", neg, char_count_same),
        pair("<", ">", neg, char_count_same),
        pair("'", "'", neg, even_count),
        pair('"', '"', neg, even_count),
        pair("`", "`", neg, even_count),
        s({trig = "{,", wordTrig = false}, {t({"{", "\t"}), i(1), t({"", "}"})})
    },
    java = {
        s({trig="fn"}, {
            d(6, jdocsnip, {2, 4, 5}), t({"", ""}),
            c(1, {
                t({"public "}),
                t({"private "})
            }),
            c(2, {
                t({"void"}),
                i(nil, {""}),
                t({"String"}),
                t({"char"}),
                t({"int"}),
                t({"double"}),
                t({"boolean"}),
            }),
            t({" "}),
            i(3, {"myFunc"}),
            t({"("}), i(4), t({")"}),
            c(5, {
                t({""}),
                sn(nil, {
                    t({""," throws "}),
                    i(1)
                })
            }),
            t({" {", "\t"}),
            i(0),
            t({"", "}"})
        }),
        s("clazz", {
            -- Choice: Switch between two different Nodes, first parameter is its position, second a list of nodes.
            c(1, {
                t("public "),
                t("private "),
            }),
            t("class "),
            i(2),
            t(" "),
            c(3, {
                t("{"),
                -- sn: Nested Snippet. Instead of a trigger, it has a position, just like insert-nodes. !!! These don't expect a 0-node!!!!
                -- Inside Choices, Nodes don't need a position as the choice node is the one being jumped to.
                sn(nil, {
                    t("extends "),
                    i(1),
                    t(" {"),
                }),
                sn(nil, {
                    t("implements "),
                    i(1),
                    t(" {"),
                }),
            }),
            t({ "", "\t" }),
            i(0),
            t({ "", "}" }),
        }),
        ls.parser.parse_snippet({trig = 'psvm'}, "private static void main(String[] args) {\n\t$0\n}"),
        ls.parser.parse_snippet({trig = 'psf'}, "private static final $0"),
        ls.parser.parse_snippet({trig = 'pf'}, "private final $0")
    }
    -- rust = {ls.parser.parse_snippet({trig = "fn"}, "/// $1\nfn $2($3) ${4:-> $5 }\\{\n\t$0\n\\}")}
}
-- LuaFormatter on

require("luasnip.loaders.from_vscode").load()

set_keymap('i', '<C-k>', "<cmd>lua return require'luasnip'.expand_or_jump()<CR>")
set_keymap('i', '<C-j>', "<cmd>lua return require'luasnip'.jump(-1)<CR>")
set_keymap('i', '<C-n>', "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'", {silent = true, expr = true})
set_keymap('s', '<C-n>', "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'", {silent = true, expr = true})
