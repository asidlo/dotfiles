local M = {}

local function get_client()
  local clients = vim.lsp.get_active_clients()
  for _, client in pairs(clients) do
    if client.name == 'jdtls' then
      return client
    end
  end
end

local function has_extended_support(client)
  return client.config.init_options and client.config.init_options.extendedClientCapabilities
end

local function has_classfile_support(client)
  return has_extended_support(client) and client.config.init_options.extendedClientCapabilities.classFileContentsSupport
end

local function handle_request(client, method, params, bufnr)
  local response = nil
  local cb = function(err, _, result)
    response = {err, result}
  end

  local ok, request_id = client.request(method, params, cb, bufnr)
  assert(ok, 'Request method='..method..'; params='..vim.inspect(params)..' failed, check if the client'..'('..client.name..') is shutdown?')

  local wait_ok, reason = vim.wait(1000, function() return response end)
  local wait_failure = {
    [-1] = 'timeout';
    [-2] = 'interrupted';
    [-3] = 'error'
  }

  if wait_ok then
    return response[1], response[2]
  else
    client.cancel_request(request_id)
    return 'Request error occured while waiting, reason='..wait_failure[reason], nil
  end
end

-- Reads the uri into the current buffer
--
-- This requires at least one open buffer that is connected to the jdtls
-- language server.
--
--@param uri string in the form of a `jdt://` uri
function M.open_jdt_link(uri)
  local client = get_client()
  assert(client, 'Must have jdtls client connected to buffer to load JDT URI')

  if not has_classfile_support(client) then
    error('Must have client.config.init_options.extendedClientCapabilities.classFileContentsSupport enabled')
  end

  local buf = vim.api.nvim_get_current_buf()

  local err, result = handle_request(client, 'java/classFileContents', { uri = uri }, buf)
  if err then
    error('Unable to complete request; error='..vim.inspect(err))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, '\n', true))
  vim.api.nvim_buf_set_option(0, 'filetype', 'java')
  vim.api.nvim_buf_set_option(0, 'modifiable', false)
  vim.api.nvim_buf_set_option(0, 'modified', false)
  vim.api.nvim_buf_set_option(0, 'readonly', true)

  -- for some reason, the client keeps getting detached from the buffer
  vim.lsp.buf_attach_client(buf, client.id)
end

-- -- Until https://github.com/neovim/neovim/pull/11607 is merged
-- local function execute_command(command, callback)
--   vim.lsp.buf_request(0, 'workspace/executeCommand', command, function(err, _, resp)
--     if callback then
--       callback(err, resp)
--     elseif err then
--       print("Could not execute code action: " .. err.message)
--     end
--   end)
-- end

-- local function with_classpaths(fn)
--   local options = vim.fn.json_encode({
--     scope = 'runtime';
--   })
--   local cmd = {
--     command = 'java.project.getClasspaths';
--     arguments = { vim.uri_from_bufnr(0), options };
--   }
--   execute_command(cmd, function(err, resp)
--     if err then
--       print('Error executing java.project.getClasspaths: ' .. err.message)
--     else
--       fn(resp)
--     end
--   end)
-- end

-- local function with_java_executable(mainclass, project, fn)
--   vim.validate({
--     mainclass = { mainclass, 'string' }
--   })
--   execute_command({
--     command = 'vscode.java.resolveJavaExecutable',
--     arguments = { mainclass, project }
--   }, function(err, java_exec)
--     if err then
--       print('Could not resolve java executable: ' .. err.message)
--     else
--       fn(java_exec)
--     end
--   end)
-- end

-- local function resolve_classname()
--   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
--   local pkgname
--   for _, line in ipairs(lines) do
--     local match = line:match('package ([a-z\\.]+);')
--     if match then
--       pkgname = match
--       break
--     end
--   end
--   assert(pkgname, 'Could not find package name for current class')
--   local classname = vim.fn.fnamemodify(vim.fn.expand('%'), ':t:r')
--   return pkgname .. '.' .. classname
-- end

-- function M.jshell()
--   with_classpaths(function(result)
--     local buf = vim.api.nvim_create_buf(false, true)
--     local classpaths = {}
--     for _, path in pairs(result.classpaths) do
--       if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
--         table.insert(classpaths, path)
--       end
--     end
--     local cp = table.concat(classpaths, ':')
--     with_java_executable(resolve_classname(), '', function(java_exec)
--       vim.api.nvim_win_set_buf(0, buf)
--       local jshell = vim.fn.fnamemodify(java_exec, ':h') .. '/jshell'
--       vim.fn.termopen({jshell, '--class-path', cp})
--     end)
--   end)
-- end

return M