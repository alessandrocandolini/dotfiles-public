local M = {}

-- A separate editor keeps its input loop running while the spec asserts on it.
-- It loads the real config using the test shell's isolated HOME and XDG paths.
function M.start()
  local stderr = {}
  local job = vim.fn.jobstart({
    vim.v.progpath, '--embed', '--headless', '-n', '-i', 'NONE', '-u', 'nvim-tests/init_test.lua',
  }, {
    rpc = true,
    on_stderr = function(_, lines) vim.list_extend(stderr, lines) end,
  })
  assert(job > 0, 'could not start test editor')
  vim.rpcrequest(job, 'nvim_ui_attach', 100, 35, { rgb = true })
  local editor = {}
  function editor.exec(code, ...)
    return vim.rpcrequest(job, 'nvim_exec_lua', code, { ... })
  end
  function editor.keys(keys)
    vim.rpcrequest(job, 'nvim_input', keys)
  end
  function editor.wait(code)
    local ok = vim.wait(2000, function() return editor.exec(code) end, 10)
    if not ok then
      error('timed out: ' .. code .. '\n' .. vim.inspect(editor.exec([[
        return { lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
          mode = vim.api.nvim_get_mode(), completion = vim.fn.complete_info(), error = vim.v.errmsg }
      ]])) .. '\n' .. table.concat(stderr, '\n'))
    end
  end
  function editor.close()
    pcall(vim.rpcrequest, job, 'nvim_command', 'qa!')
    vim.fn.jobwait({ job }, 1000)
    vim.fn.jobstop(job)
  end
  return editor
end

return M
