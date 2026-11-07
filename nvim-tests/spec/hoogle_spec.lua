local hoogle = require('config.hoogle')

local function wait_for(predicate)
  assert(vim.wait(5000, predicate, 20), 'timed out waiting for Hoogle picker')
end

describe('Live Hoogle search', function()
  local system, executable, picker, register
  local reload, options, requests
  local maximum = {
    item = 'maximum :: (Foldable t, Ord a) => t a -> a',
    module = { name = 'Prelude' }, package = { name = 'base' },
    docs = '<p>The <tt>largest</tt> element.</p><pre>&gt;&gt;&gt; maximum [1, 4]\n4</pre>&#955; &amp; &#x3bb;',
  }

  before_each(function()
    system, executable = vim.system, vim.fn.executable
    picker, register = require('fzf-lua').fzf_live, vim.fn.getreginfo('"')
    requests = {}
    vim.fn.executable = function(name) return name == 'hoogle' and 1 or executable(name) end
    vim.system = function(args, opts, callback)
      if args[1] ~= 'hoogle' then return system(args, opts, callback) end
      local request = { args = args, reply = callback }
      requests[#requests + 1] = request
      return { kill = function() request.killed = true end }
    end
    require('fzf-lua').fzf_live = function(fn, opts) reload, options = fn, opts end
    vim.cmd.enew()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unchanged source' })
    hoogle.search()
  end)

  after_each(function()
    if options then options.winopts.on_close() end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'fzf' then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
    vim.system, vim.fn.executable = system, executable
    require('fzf-lua').fzf_live = picker
    vim.fn.setreg('"', register)
    vim.cmd('stopinsert')
    vim.cmd('bwipeout!')
  end)

  local function query(text)
    local result = { entries = {} }
    reload({ text })(function(entry)
      if entry then result.entries[#result.entries + 1] = entry else result.done = true end
    end)
    return result
  end

  local function reply(request, result)
    request.reply({ code = 0, stdout = vim.json.encode(result) })
  end

  it('queries typed signatures without HLS and copies names without editing source', function()
    assert.equals(0, #vim.lsp.get_clients({ bufnr = 0 }))
    local result = query('Ord a => [a] -> a')
    assert.same({ 'hoogle', 'search', '--json', '--count=50', 'Ord a => [a] -> a' }, requests[1].args)
    reply(requests[1], { maximum })
    wait_for(function() return result.done end)
    options.actions.enter({ result.entries[1] })
    assert.equals('maximum', vim.fn.getreg('"'))
    assert.equals('unchanged source', vim.api.nvim_get_current_line())
  end)

  it('routes an actual hover action to an editable local Hoogle query', function()
    local ht = require('haskell-tools')
    hoogle.connect_hover(ht)
    local connected = ht.hoogle.hoogle_signature
    hoogle.connect_hover(ht)
    assert.equals(connected, ht.hoogle.hoogle_signature)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'maximum' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local buf = vim.api.nvim_get_current_buf()
    local signature = '(Foldable t, Ord a) => t a -> a'
    local _, win = require('haskell-tools.lsp.hover').on_hover(nil, {
      contents = { kind = 'markdown', value = '```haskell\nmaximum :: ' .. signature .. '\n```' },
    }, { bufnr = buf, method = 'textDocument/hover', params = {
      textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 0 },
    } }, {})
    vim.api.nvim_set_current_win(win)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      if line:find('Hoogle search: `' .. signature .. '`', 1, true) then
        vim.api.nvim_win_set_cursor(win, { i, 0 })
        vim.fn.maparg('<CR>', 'n', false, true).callback()
        break
      end
    end
    wait_for(function() return options.query == signature end)
    assert.is_false(vim.api.nvim_win_is_valid(win))
    local result = query(options.query)
    assert.equals(signature, requests[1].args[5])
    reply(requests[1], { maximum })
    wait_for(function() return result.done end)
    assert.matches('maximum', result.entries[1])
  end)

  it('passes punctuation as one argument and skips empty input', function()
    assert.is_true(query('  ').done)
    assert.equals(0, #requests)
    query("(a -> b) -> [a] -> [b] +base ' ; $(test)")
    assert.equals("(a -> b) -> [a] -> [b] +base ' ; $(test)", requests[1].args[5])
  end)

  it('cancels superseded searches and ignores their late responses', function()
    local old = query('map')
    local current = query('maximum')
    assert.is_true(requests[1].killed)
    reply(requests[2], { maximum })
    reply(requests[1], { { item = 'map :: (a -> b) -> [a] -> [b]' } })
    wait_for(function() return old.done and current.done end)
    assert.same({}, old.entries)
    assert.matches('maximum', current.entries[1])
    query('minimum')
    options.winopts.on_close()
    assert.is_true(requests[3].killed)
  end)

  it('shows readable docs, examples, and a fallback for undocumented entries', function()
    local result = query('maximum')
    reply(requests[1], { maximum, { item = 'other :: a -> a' } })
    wait_for(function() return result.done end)
    assert.equals(maximum.item .. '\nbase\nPrelude\n\nThe largest element.\n>>> maximum [1, 4]\n4\nλ & λ',
      options.preview({ result.entries[1] }))
    assert.matches('No documentation available.', options.preview({ result.entries[2] }), 1, true)
    assert.equals('', options.preview({}))
  end)

  it('shows no-results and parse errors in the picker without changing the register', function()
    vim.fn.setreg('"', 'keep me')
    for _, text in ipairs({ 'No results found\n', 'Parse error at end of input' }) do
      local result = query('a ->')
      requests[#requests].reply({ code = 0, stdout = text })
      wait_for(function() return result.done end)
      assert.equals('Hoogle: ' .. vim.trim(text), result.entries[1])
      options.actions.enter({ result.entries[1] })
      assert.equals('keep me', vim.fn.getreg('"'))
    end
  end)

  it('refreshes results while typing and toggles documentation in the real split', function()
    picker(reload, options)
    local terminal, window
    wait_for(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'fzf' then terminal, window = buf, win; return true end
      end
    end)
    assert.equals('', vim.api.nvim_win_get_config(window).relative)
    local job = vim.b[terminal].terminal_job_id
    local function contains(text)
      return table.concat(vim.api.nvim_buf_get_lines(terminal, 0, -1, false), '\n'):find(text, 1, true) ~= nil
    end
    vim.api.nvim_chan_send(job, 'Ord a => [a] -> a')
    wait_for(function() return #requests > 0 and requests[#requests].args[5] == 'Ord a => [a] -> a' end)
    reply(requests[#requests], { maximum })
    wait_for(function() return contains('maximum ::') end)
    vim.api.nvim_chan_send(job, '\x1f')
    wait_for(function() return contains('The largest element.') end)
    vim.api.nvim_chan_send(job, '\x15minimum')
    wait_for(function() return requests[#requests].args[5] == 'minimum' end)
    reply(requests[#requests], { { item = 'minimum :: Ord a => [a] -> a', module = { name = 'Prelude' } } })
    wait_for(function() return contains('minimum ::') end)
    vim.api.nvim_chan_send(job, '\r')
    wait_for(function() return not vim.api.nvim_win_is_valid(window) end)
    assert.equals('minimum', vim.fn.getreg('"'))
    assert.equals('unchanged source', vim.api.nvim_get_current_line())
  end)
end)
