local M = {}

function M.attach(editor, width, height)
  local screen = { frames = {} }
  local pipe = vim.uv.new_pipe(false)
  local address = editor.exec('return vim.fn.serverstart()')
  local connected
  pipe:connect(address, function(err)
    screen.error = err
    connected = true
  end)
  assert(vim.wait(2000, function() return connected end, 10), 'screen connection timed out')
  assert(not screen.error, screen.error)

  local rows, cursor = {}, {}
  local function clear()
    rows = {}
    for row = 1, height do
      rows[row] = {}
      for col = 1, width do rows[row][col] = ' ' end
    end
  end
  clear()
  local function redraw(events)
    for _, event in ipairs(events) do
      for i = 2, #event do
        local args = event[i]
        if event[1] == 'grid_resize' and args[1] == 1 then
          width, height = args[2], args[3]
          clear()
        elseif event[1] == 'grid_clear' and args[1] == 1 then
          clear()
        elseif event[1] == 'grid_line' and args[1] == 1 then
          local row, col = rows[args[2] + 1], args[3] + 1
          for _, cell in ipairs(args[4]) do
            for _ = 1, cell[3] or 1 do
              row[col] = cell[1]
              col = col + 1
            end
          end
        elseif event[1] == 'grid_scroll' and args[1] == 1 then
          local previous = vim.deepcopy(rows)
          for row = args[2] + 1, args[3] do
            for col = args[4] + 1, args[5] do
              local source_row, source_col = row + args[6], col + args[7]
              rows[row][col] = source_row > args[2] and source_row <= args[3]
                and source_col > args[4] and source_col <= args[5]
                and previous[source_row][source_col] or ' '
            end
          end
        elseif event[1] == 'grid_cursor_goto' and args[1] == 1 then
          cursor = { args[2], args[3] }
        elseif event[1] == 'flush' then
          screen.frames[#screen.frames + 1] = {
            cursor = vim.deepcopy(cursor), message = table.concat(rows[height]),
          }
        end
      end
    end
  end

  local unpacker, responses, request_id = vim.mpack.Unpacker(), {}, 0
  pipe:read_start(function(err, data)
    if err then screen.error = err end
    if not data then return end
    local ok, failure = pcall(function()
      local pos = 1
      while pos <= #data do
        local message
        message, pos = unpacker(data, pos)
        if message and message[1] == 2 and message[2] == 'redraw' then
          redraw(message[3])
        elseif message and message[1] == 1 then
          responses[message[2]] = message
        end
      end
    end)
    if not ok then screen.error = failure end
  end)

  local function request(method, args)
    request_id = request_id + 1
    local id = request_id
    pipe:write(vim.mpack.encode({ 0, id, method, args }))
    assert(vim.wait(2000, function() return responses[id] or screen.error end, 10), 'screen request timed out')
    assert(not screen.error, screen.error)
    local response = responses[id]
    responses[id] = nil
    assert(response[3] == vim.NIL, vim.inspect(response[3]))
  end

  function screen.sync() request('nvim_eval', { '0' }) end
  function screen.close()
    if not pipe:is_closing() then pipe:read_stop(); pipe:close() end
    pcall(editor.exec, 'vim.fn.serverstop(...)', address)
  end

  request('nvim_ui_attach', { width, height, { rgb = true, ext_linegrid = true } })
  screen.sync()
  return screen
end

return M
