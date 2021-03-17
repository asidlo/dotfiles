function _G.replace_termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function _G.new_buf(...)
  local objects = vim.tbl_map(vim.inspect, {...})
  local buf = vim.api.nvim_create_buf(true, true)
  local content = {}
  for _, obj in ipairs(objects) do
    for _, line in ipairs(vim.split(obj, '\n')) do
      table.insert(content, line)
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)
  vim.cmd('b '..buf)
end

function _G.lsp_clients()
  return vim.lsp.buf_get_clients()
end

function _G.has_document_symbol_support(client)
  return client.resolved_capabilities.document_symbol ~= nil
end

function _G.has_document_definition_support(client)
  return client.resolved_capabilities.textDocument_definition ~= nil
end

function _G.lsp_handlers()
  return vim.tbl_keys(vim.lsp.handlers)
end

function _G.is_buffer_empty()
    -- Check whether the current buffer is empty
    return vim.fn.empty(vim.fn.expand('%:t')) == 1
end

function _G.has_width_gt(cols)
    -- Check if the windows width is greater than a given number of columns
    return vim.fn.winwidth(0) / 2 > cols
end

function _G.nvim_create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		vim.api.nvim_command('augroup '..group_name)
		vim.api.nvim_command('autocmd!')
		for _, def in ipairs(definition) do
			local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
			vim.api.nvim_command(command)
		end
		vim.api.nvim_command('augroup END')
	end
end

-- http://lua-users.org/wiki/StringTrim #6
function _G.trim(s)
  if s == nil then
    return nil
  end
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end
