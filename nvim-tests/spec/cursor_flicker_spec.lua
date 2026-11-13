local editor = require('helpers.editor')

local function observe_cursor(e)
  local screen = { frames = {} }
  local pipe = vim.uv.new_pipe(false)
  local address = e.exec('return vim.fn.serverstart()')
  local connected
  pipe:connect(address, function(err)
    screen.error = err
    connected = true
  end)
  assert(vim.wait(2000, function() return connected end, 10), 'screen connection timed out')
  assert(not screen.error, screen.error)

  local unpacker, responses, request_id = vim.mpack.Unpacker(), {}, 0
  local cursor
  pipe:read_start(function(err, data)
    if err then screen.error = err end
    if not data then return end
    local ok, failure = pcall(function()
      local pos = 1
      while pos <= #data do
        local message
        message, pos = unpacker(data, pos)
        if message and message[1] == 2 and message[2] == 'redraw' then
          for _, event in ipairs(message[3]) do
            for i = 2, #event do
              if event[1] == 'grid_cursor_goto' then
                cursor = event[i]
              elseif event[1] == 'flush' and cursor then
                screen.frames[#screen.frames + 1] = {
                  grid = cursor[1], row = cursor[2] + 1, col = cursor[3] + 1,
                }
              end
            end
          end
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

  function screen.sync()
    request('nvim_eval', { '0' })
  end

  function screen.close()
    if not pipe:is_closing() then
      pipe:read_stop()
      pipe:close()
    end
    pcall(e.exec, 'vim.fn.serverstop(...)', address)
  end

  request('nvim_ui_attach', { 60, 8, { rgb = true, ext_linegrid = true } })
  screen.sync()
  return screen
end

describe('automatic completion cursor redraw', function()
  local e, screen

  after_each(function()
    if screen then screen.close(); screen = nil end
    if e then e.close(); e = nil end
  end)

  local function keeps_cursor(showmode)
    e = editor.start()
    if showmode then e.exec('vim.o.showmode = true') end
    e.exec([[
      completion_calls = 0
      local server = require('helpers.lsp').server({ completionProvider = {}, textDocumentSync = 1 }, {
        ['textDocument/completion'] = function(_, reply)
          completion_calls = completion_calls + 1
          reply({ isIncomplete = true, items = {} })
        end,
      })
      client_id = vim.lsp.start({ name = 'cursor-completion-probe', cmd = server.cmd })
    ]])
    e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
    screen = observe_cursor(e)
    e.keys('i')
    e.wait('return vim.api.nvim_get_mode().mode == "i"')
    screen.sync()
    screen.frames = {}

    for char in ('qqqz'):gmatch('.') do
      e.exec('completion_calls = 0')
      e.keys(char)
      e.wait('return completion_calls > 0')
      screen.sync()
    end

    assert.equals('qqqz', e.exec('return vim.fn.getline(1)'))
    assert.same({ 1, 4 }, e.exec('return vim.api.nvim_win_get_cursor(0)'))
    assert.is_true(#screen.frames > 0, 'the observer must receive flushed cursor positions')
    local misplaced = {}
    for index, frame in ipairs(screen.frames) do
      if frame.grid ~= 1 or frame.row ~= 1 then
        misplaced[#misplaced + 1] = { flush = index, cursor = frame }
      end
    end
    assert.same({}, misplaced, 'the UI cursor jumped away from the editing row')
  end

  it('keeps the cursor on the editing row at every flush of a 60x8 screen', function()
    keeps_cursor(false)
  end)

  if vim.env.NVIM_COMPLETION_DIAGNOSTICS == '1' then
    it('keeps the cursor on the editing row with the mode label visible', function()
      keeps_cursor(true)
    end)
  end
end)
