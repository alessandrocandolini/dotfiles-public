local M = {}

-- An in-process LSP transport: exercise Neovim's actual initialization,
-- attachment, requests and restart without launching a language server.
function M.server(capabilities, handlers)
  local server = { connections = {}, requests = {} }
  server.cmd = function(dispatchers)
    local connection = { closing = false }
    table.insert(server.connections, connection)
    local request_id = 0
    local function terminate()
      if connection.closing then return end
      connection.closing = true
      vim.schedule(function() dispatchers.on_exit(0, 0) end)
    end
    return {
      request = function(method, params, callback, notify_reply)
        request_id = request_id + 1
        local id = request_id
        table.insert(server.requests, { method = method, params = params })
        vim.schedule(function()
          local function reply(result)
            callback(nil, result)
            if notify_reply then notify_reply(id) end
          end
          if handlers and handlers[method] then
            handlers[method](params, reply)
            return
          end
          local result
          if method == 'initialize' then
            result = { capabilities = capabilities or {} }
          elseif method == 'textDocument/formatting' then
            result = { {
              range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
              newText = '// formatted\n',
            } }
          end
          reply(result)
        end)
        return true, id
      end,
      notify = function(method)
        if method == 'exit' then terminate() end
        return true
      end,
      is_closing = function() return connection.closing end,
      terminate = terminate,
    }
  end
  function server.count(method)
    return #vim.tbl_filter(function(request) return request.method == method end, server.requests)
  end
  return server
end

function M.wait_for(predicate)
  assert(vim.wait(1000, predicate, 5), 'timed out waiting for LSP lifecycle')
end

function M.stop_clients()
  for _, client in ipairs(vim.lsp.get_clients({ _uninitialized = true })) do
    client:stop(true)
  end
  M.wait_for(function()
    return #vim.lsp.get_clients({ _uninitialized = true }) == 0
  end)
end

return M
