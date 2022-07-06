function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, { ... })
    print(table.unpack(objects))
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

-- Appends content followed by a newline char to a file
_G.append_to_file = function(content, file)
    local out = io.open(file, 'a')
    if not out then
        return
    end
    out:write(content)
    out:write('\n')
    out:close()
end

_G.add_to_dictionary = function(word)
    vim.cmd('normal! ma')
    local dict = vim.fn.expand('~/.config/vale/styles/en.utf-8.add')
    append_to_file(word, dict)
    print(string.format('Added %s to dictionary %s', word, dict))

    -- To remove the diagnostic popup and underline
    vim.cmd('e')

    vim.cmd('normal! `a')
end
