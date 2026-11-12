local editor = require('helpers.editor')
local fs = require('helpers.fs')

describe('completion and snippets', function()
  local e, root

  local function open(path)
    e.exec('vim.cmd.edit(vim.fn.fnameescape(...))', root .. '/' .. path)
  end

  local function menu()
    e.wait('return completion.visible() == 1')
    return e.exec([[return vim.tbl_map(function(item) return item.word end, completion.info().items)]])
  end

  local function start_server()
    e.exec([[
      pending = {}
      server = require('helpers.lsp').server({
        textDocumentSync = 1,
        completionProvider = { triggerCharacters = { '.' }, resolveProvider = true },
      }, {
        ['textDocument/completion'] = function(params, reply)
          pending[#pending + 1] = function()
            reply({ isIncomplete = false, items = {
              {
                label = 'iterate', kind = 3, insertTextFormat = 2, data = true,
                textEdit = {
                  range = { start = { line = params.position.line, character = 0 }, ['end'] = params.position },
                  newText = 'iterate($' .. '{1:value})$0',
                },
              },
            } })
          end
        end,
        ['completionItem/resolve'] = function(item, reply)
          item.additionalTextEdits = { {
            range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
            newText = 'import Probe\n',
          } }
          reply(item)
        end,
      })
      client_id = vim.lsp.start({ name = 'completion-fixture', cmd = server.cmd })
    ]])
    e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
  end

  local function deliver_replies()
    e.wait('return #pending > 0')
    e.exec('for _, respond in ipairs(pending) do respond() end; pending = {}')
  end

  local function reply()
    deliver_replies()
    e.wait([[return vim.tbl_contains(vim.tbl_map(function(i) return i.word end, completion.info().items), 'iterate')]])
  end

  local function select_item(word)
    local items = menu()
    for _ = 0, #items do
      if e.exec([[
        local info = completion.info()
        return info.items[info.selected + 1] and info.items[info.selected + 1].word
      ]]) == word then return end
      local selected = e.exec('return completion.info().selected')
      e.keys('<Tab>')
      e.wait('return completion.info().selected ~= ' .. selected)
    end
    error('could not select completion ' .. word)
  end

  before_each(function()
    root = vim.fn.tempname()
    fs.write_file(root .. '/src/App/Main.hs', { '' })
    fs.write_file(root .. '/test/App/MainSpec.hs', { '' })
    e = editor.start()
    -- Exercise the real Haskell ftplugin, without launching an external HLS.
    e.exec('completion = require("helpers.completion"); vim.g.haskell_tools = { hls = { auto_attach = false }, tools = { tags = { enable = false } } }; vim.cmd.lcd(...)', root)
    open('src/App/Main.hs')
  end)

  after_each(function()
    if e then e.close() end
    vim.fn.delete(root, 'rf')
  end)

  it('offers and expands local snippets automatically without an LSP', function()
    assert.equals(0, e.exec('return #vim.lsp.get_clients()'))
    assert.is_true(e.exec([[return package.loaded.cmp == nil and package.loaded.luasnip == nil]]))
    e.keys('iit')
    assert.same({ 'it' }, menu())
    e.keys('<Tab><CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('it "description" $', e.exec('return vim.fn.getline(1)'))
    e.keys('example<Tab>')
    e.wait([[return vim.fn.getline(1) == 'it "example" $' and vim.api.nvim_win_get_cursor(0)[1] == 2]])
    local actual_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
    e.keys('<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
    e.keys('<S-Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] == ' .. actual_col)
  end)

  it('uses Tab and Shift-Tab to navigate snippets before and after editing placeholders', function()
    e.keys('iit')
    menu()
    e.keys('<Tab><CR>')
    e.wait('return vim.snippet.active()')
    -- Tab also keeps working in Select mode before replacing a placeholder.
    e.keys('<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 2')
    local actual_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
    e.keys('value<Tab>')
    e.wait('return vim.api.nvim_get_mode().mode == "s" and vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
    e.keys('<S-Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] == ' .. actual_col)
    -- After typing, Shift-Tab must jump from Insert mode too.
    e.keys('result<S-Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 1')
    e.keys('example<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 2')
    e.keys('<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
    e.keys('expected<Tab>')
    e.wait('return not vim.snippet.active()')
    assert.equals('it "example" $', e.exec('return vim.fn.getline(1)'))
    assert.equals('  result `shouldBe` expected', e.exec('return vim.fn.getline(2)'))
  end)

  it('prioritizes completion navigation while editing a snippet placeholder', function()
    e.keys('iit')
    menu()
    e.keys('<Tab><CR>')
    e.wait('return vim.snippet.active()')
    e.keys('<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 2')
    e.keys('pr')
    assert.same({ 'prop' }, menu())
    local initial_selection = e.exec('return completion.info().selected')
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    assert.equals(2, e.exec('return vim.api.nvim_win_get_cursor(0)[1]'))
    e.keys('<S-Tab>')
    e.wait('return completion.info().selected == ' .. initial_selection)
    assert.equals(2, e.exec('return vim.api.nvim_win_get_cursor(0)[1]'))
    e.keys('<C-e>')
    e.wait('return completion.visible() == 0')
    e.keys('<Tab>')
    e.wait('return vim.api.nvim_get_mode().mode == "s"')
    e.keys('replacement<Tab>')
    e.wait('return not vim.snippet.active()')
    assert.equals('  pr `shouldBe` replacement', e.exec('return vim.fn.getline(2)'))
  end)

  for _, selected in ipairs({ false, true }) do
    it('keeps snippet jumps after Esc dismisses an ' .. (selected and 'explicitly selected' or 'unselected') .. ' completion', function()
      e.keys('iit')
      menu()
      e.keys('<Tab><CR>')
      e.wait('return vim.snippet.active()')
      e.keys('<Tab>')
      e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 2')
      e.keys('pr')
      assert.same({ 'prop' }, menu())
      if selected then
        e.keys('<Tab>')
        e.wait('return completion.info().selected == 0')
      end
      e.keys('<Esc>')
      e.wait([[return completion.visible() == 0 and vim.api.nvim_get_mode().mode == 'i' and vim.snippet.active()]])
      assert.equals('  pr `shouldBe` expected', e.exec('return vim.fn.getline(2)'))
      local actual_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
      e.keys('<Tab>')
      e.wait('return vim.api.nvim_get_mode().mode == "s" and vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
      local expected_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
      e.keys('<S-Tab>')
      e.wait('return vim.api.nvim_get_mode().mode == "s" and vim.api.nvim_win_get_cursor(0)[2] < ' .. expected_col)
      e.keys('pr')
      assert.same({ 'prop' }, menu())
      e.keys('<Esc>')
      e.wait([[return completion.visible() == 0 and vim.api.nvim_get_mode().mode == 'i' and vim.snippet.active()]])
      e.keys('<Esc>')
      e.wait([[return vim.api.nvim_get_mode().mode == 'n' and not vim.snippet.active()]])
      assert.equals('  pr `shouldBe` expected', e.exec('return vim.fn.getline(2)'))
    end)
  end

  local function type_then_idle(keys)
    e.keys(keys)
    vim.wait(300)
  end

  it('does not offer snippets after a space, so Enter inserts a newline', function()
    type_then_idle('iinstance ToJSON Thing where')
    type_then_idle(' ')
    assert.equals(0, e.exec('return completion.visible()'))
    e.keys('<CR>')
    e.wait('return vim.api.nvim_buf_line_count(0) == 2')
    assert.equals('instance ToJSON Thing where ', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
  end)

  it('does not ask the LSP for completions after a space', function()
    start_server()
    type_then_idle('iinstance ToJSON Thing where')
    e.exec('pending = {}')
    type_then_idle(' ')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('does not ask the LSP for completions after punctuation, but still does after a trigger character', function()
    start_server()
    type_then_idle('i{ startCycle :: Cycle')
    e.exec('pending = {}')
    type_then_idle(',')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
    type_then_idle(' Data')
    e.exec('pending = {}')
    type_then_idle('.')
    e.wait('return #pending > 0')
  end)

  it('completes on demand with Ctrl-Space even without a prefix, like cmp', function()
    start_server()
    type_then_idle('ifoo ')
    assert.equals(0, e.exec('return completion.visible()'))
    e.exec('pending = {}')
    e.keys('<C-Space>')
    assert.same({ 'it', 'prop', 'module' }, menu())
    e.wait('return #pending > 0')
    e.keys('<C-e>')
    e.wait('return completion.visible() == 0')
    e.exec('pending = {}')
    type_then_idle(' ')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('ends on-demand completion when the menu is dismissed, even if no character is typed afterwards', function()
    start_server()
    type_then_idle('ifoo ,')
    e.exec('pending = {}')
    e.keys('<C-Space>')
    menu()
    e.wait('return #pending > 0')
    e.keys('<C-e>')
    e.wait('return completion.visible() == 0')
    e.exec('pending = {}')
    type_then_idle('<BS>')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('completes on demand with Nul, the key many terminals send for Ctrl-Space', function()
    start_server()
    type_then_idle('ifoo ')
    assert.equals(0, e.exec('return completion.visible()'))
    e.exec('pending = {}')
    e.keys('<Nul>')
    assert.same({ 'it', 'prop', 'module' }, menu())
    e.wait('return #pending > 0')
  end)

  it('forces fresh LSP results on every manual trigger, including an already open menu', function()
    start_server()
    type_then_idle('ifoo ')
    e.keys('<C-Space>')
    menu()
    reply()
    for _, key in ipairs({ '<C-Space>', '<Nul>' }) do
      local requests = e.exec([[return server.count('textDocument/completion')]])
      e.keys(key)
      e.wait([[return server.count('textDocument/completion') > ]] .. requests)
      e.wait('return #pending > 0')
      reply()
      assert.equals(4, #menu())
      assert.equals('foo ', e.exec('return vim.fn.getline(1)'))
    end
  end)

  it('does not complete when entering insert mode after existing text, only after typing', function()
    start_server()
    e.exec([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'duration (AddX _) = 2' })]])
    e.exec('pending = {}')
    e.keys('$a')
    vim.wait(400)
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
    type_then_idle('2')
    e.wait('return #pending > 0')
  end)

  it('inserts a newline on Enter while the menu is open but nothing is selected', function()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    assert.equals(-1, e.exec('return completion.info().selected'))
    e.keys('<CR>')
    e.wait('return vim.api.nvim_buf_line_count(0) == 2')
    assert.equals('it', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
  end)

  it('discards a highlighted candidate on Esc and keeps the typed text', function()
    e.keys('ipr')
    assert.same({ 'prop' }, menu())
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    assert.equals('pr', e.exec('return vim.fn.getline(1)'))
    e.keys('<Esc>')
    e.wait([[return vim.api.nvim_get_mode().mode == 'n']])
    assert.equals('pr', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('autocompletes module headers without LSP, including in a new unsaved source file', function()
    fs.write_file(root .. '/cabal.project', {})
    open('src/App/Fresh.hs')
    assert.equals(0, e.exec('return #vim.lsp.get_clients()'))
    assert.equals(0, e.exec('return vim.fn.filereadable(vim.api.nvim_buf_get_name(0))'))
    e.keys('imod')
    assert.same({ 'module' }, menu())
    e.keys('<Tab><CR>')
    e.wait([[return vim.fn.getline(1) == 'module App.Fresh where']])
    assert.same({ 'module App.Fresh where', '', '' }, e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
    assert.equals(0, e.exec('return #vim.lsp.get_clients()'))
    assert.equals(0, e.exec('return vim.fn.filereadable(vim.api.nvim_buf_get_name(0))'))
    e.keys('<Esc>')
    e.exec('vim.bo.modified = false')
    open('test/App/MainSpec.hs')
    e.keys('imod')
    assert.same({ 'module' }, menu())
    e.keys('<Tab><CR>')
    e.wait([[return vim.fn.getline(1) == 'module App.MainSpec where']])
    assert.equals('import Test.Hspec', e.exec('return vim.fn.getline(3)'))
    assert.equals('spec = do', e.exec('return vim.fn.getline(8)'))
  end)

  it('keeps module snippets independent of directories above the project', function()
    local cases = {
      { project = 'src/project', marker = 'cabal.project', file = 'test/App/MainSpec.hs', kind = 'test', name = 'App.MainSpec' },
      { project = 'test/project', marker = 'package.yaml', file = 'src/App/Main.hs', kind = 'src', name = 'App.Main' },
      { project = 'src/project', marker = 'cabal.project', file = 'Main.hs' },
      { project = 'src/workspace/pkg', marker = 'pkg.cabal', file = 'test/App/MainSpec.hs', kind = 'test', name = 'App.MainSpec' },
      { project = 'src/unmarked', file = 'test/App/MainSpec.hs', kind = 'test', name = 'App.MainSpec' },
    }
    for _, case in ipairs(cases) do
      if case.marker then fs.write_file(root .. '/' .. case.project .. '/' .. case.marker, {}) end
      local file = case.project .. '/' .. case.file
      fs.write_file(root .. '/' .. file, { '' })
      open(file)
      e.keys('imod')
      if case.kind then
        assert.same({ 'module' }, menu())
        local body = e.exec('return completion.info().items[1].user_data.local_snippet')
        assert.equals('module ' .. case.name .. ' where', vim.split(body, '\n')[1])
        assert.equals(case.kind == 'test', body:find('import Test.Hspec', 1, true) ~= nil)
      else
        vim.wait(150)
        assert.equals(0, e.exec('return completion.visible()'))
      end
      e.keys('<Esc>')
      e.wait('return vim.api.nvim_get_mode().mode == "n"')
      e.exec('vim.bo.modified = false')
    end
  end)

  it('keeps local results while a late-attaching LSP completes asynchronously', function()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    start_server()
    e.keys('<C-e><C-Space>')
    e.wait('return #pending > 0')
    assert.same({ 'it' }, menu())
    reply()
    assert.equals(2, #menu())
    e.keys('<C-e>')
    e.wait('return completion.visible() == 0')
    assert.equals('it', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
  end)

  it('expands a local result from the mixed menu using Enter', function()
    start_server()
    e.keys('iit')
    menu()
    reply()
    select_item('it')
    e.keys('<CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('it "description" $', e.exec('return vim.fn.getline(1)'))
  end)

  it('ignores a delayed LSP reply after switching to a different buffer', function()
    start_server()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    e.wait('return #pending > 0')
    e.keys('<Esc>')
    e.wait([[return vim.api.nvim_get_mode().mode == 'n']])
    e.exec('vim.bo.modified = false')
    open('test/App/MainSpec.hs')
    assert.equals(0, e.exec('return #vim.lsp.get_clients({ bufnr = 0 })'))
    e.keys('iit')
    assert.same({ 'it' }, menu())

    -- Servers may still reply after cancellation. The old buffer's results
    -- must not enter this buffer's completion menu.
    deliver_replies()
    assert.same({ 'it' }, menu())
  end)

  it('preserves the selected local item when a delayed LSP reply arrives', function()
    start_server()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    e.wait('return #pending > 0')
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    reply()
    assert.equals('it', e.exec([[
      local info = completion.info()
      return info.items[info.selected + 1] and info.items[info.selected + 1].word
    ]]))
  end)

  it('accepts an LSP snippet, resolves its import, and uses the same jump keys', function()
    start_server()
    e.exec([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { '', '', '' }); vim.api.nvim_win_set_cursor(0, { 3, 0 })]])
    e.keys('iit')
    menu()
    reply()
    select_item('iterate')
    e.keys('<CR>')
    e.wait([[return vim.fn.getline(1) == 'import Probe' and vim.snippet.active()]])
    assert.equals('iterate(value)', e.exec('return vim.fn.getline(4)'))
    e.keys('argument<Tab>')
    e.wait('return not vim.snippet.active()')
    assert.equals('iterate(argument)', e.exec('return vim.fn.getline(4)'))
  end)

  it('survives LSP restart and still completes locally after detachment', function()
    start_server()
    e.exec('old_id = client_id; vim.cmd("lsp restart")')
    e.wait([[local c = vim.lsp.get_clients({name='completion-fixture'})[1]; return c and c.id ~= old_id and c.initialized]])
    e.keys('iit')
    menu()
    reply()
    e.keys('<Esc>')
    e.exec('require("helpers.lsp").stop_clients()')
    e.keys('a<C-Space>')
    assert.same({ 'it' }, menu())
  end)

  it('can accept a local snippet from completion and undo the expansion', function()
    e.keys('iprop')
    menu()
    e.keys('<Tab><CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('prop "description" $', e.exec('return vim.fn.getline(1)'))
    e.keys('<Esc>u')
    e.wait([[return not vim.fn.getline(1):find('description', 1, true)]])
    assert.equals(1, e.exec('return vim.api.nvim_buf_line_count(0)'))
  end)


  it('expands the prop snippet after existing text without replacing its prefix', function()
    e.keys('i  around $ pr')
    assert.same({ 'prop' }, menu())
    e.keys('<Tab><CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('  around $ prop "description" $', e.exec('return vim.fn.getline(1)'))
    e.wait('return vim.api.nvim_get_mode().mode == "s"')
    e.keys('example<Tab>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[1] == 2 and vim.api.nvim_get_mode().mode == "s"')
    local actual_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
    e.keys('result<Tab>')
    e.wait('return vim.api.nvim_get_mode().mode == "s" and vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
    e.keys('wanted<Tab>')
    e.wait('return not vim.snippet.active()')
    assert.equals('  around $ prop "example" $', e.exec('return vim.fn.getline(1)'))
    assert.equals('    result `shouldBe` wanted', e.exec('return vim.fn.getline(2)'))
  end)

  it('does not request or display completions after a tab or newline', function()
    start_server()
    for _, key in ipairs({ '<Tab>', '<CR>' }) do
      type_then_idle('iunknown')
      e.exec('pending = {}')
      type_then_idle(key)
      assert.equals(0, e.exec('return #pending'))
      assert.equals(0, e.exec('return completion.visible()'))
      e.keys('<Esc>')
      e.wait('return vim.api.nvim_get_mode().mode == "n"')
      e.exec('vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })')
    end
  end)

  it('does not complete merely when entering insert mode after an LSP trigger character', function()
    start_server()
    e.exec([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Data.' }); pending = {}]])
    type_then_idle('A')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
    e.keys('m')
    e.wait('return #pending > 0')
  end)

  it('keeps the automatic menu unselected until Tab, then accepts with Enter', function()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    assert.equals(-1, e.exec('return completion.info().selected'))
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    e.keys('<CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('it "description" $', e.exec('return vim.fn.getline(1)'))
  end)

  it('does not reopen completion when a delayed reply arrives after whitespace', function()
    start_server()
    e.keys('iit')
    menu()
    e.wait('return #pending > 0')
    type_then_idle(' ')
    assert.equals(0, e.exec('return completion.visible()'))
    e.exec('for _, respond in ipairs(pending) do respond() end; pending = {}')
    vim.wait(150)
    assert.equals(0, e.exec('return completion.visible()'))
    assert.equals('it ', e.exec('return vim.fn.getline(1)'))
  end)

  it('highlights candidates with Tab and Shift-Tab without editing until Enter', function()
    type_then_idle('ifoo ')
    e.keys('<C-Space>')
    assert.same({ 'it', 'prop', 'module' }, menu())
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    assert.equals('foo ', e.exec('return vim.fn.getline(1)'))
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 1')
    assert.equals('foo ', e.exec('return vim.fn.getline(1)'))
    e.keys('<S-Tab>')
    e.wait('return completion.info().selected == 0')
    assert.equals('foo ', e.exec('return vim.fn.getline(1)'))
    e.keys('<CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('foo it "description" $', e.exec('return vim.fn.getline(1)'))
  end)

  it('does not complete when re-entering Insert after x :: In, and Enter inserts a newline', function()
    start_server()
    e.exec([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'x :: In' }); pending = {}]])
    type_then_idle('A')
    assert.equals(0, e.exec('return #pending'))
    assert.equals(0, e.exec('return completion.visible()'))
    e.keys('<CR>')
    e.wait('return vim.api.nvim_buf_line_count(0) == 2')
    assert.equals('x :: In', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('offers Int and Integer while typing a Haskell type signature and accepts only the selected type', function()
    e.exec([[
      server = require('helpers.lsp').server({
        textDocumentSync = 1,
        completionProvider = {},
      }, {
        ['textDocument/completion'] = function(params, respond)
          local items = {}
          for _, name in ipairs({ 'Int', 'Integer' }) do
            items[#items + 1] = {
              label = name, kind = 7,
              textEdit = {
                range = {
                  start = { line = params.position.line, character = 5 },
                  ['end'] = params.position,
                },
                newText = name,
              },
            }
          end
          respond({ isIncomplete = false, items = items })
        end,
      })
      client_id = vim.lsp.start({ name = 'haskell-type-fixture', cmd = server.cmd })
    ]])
    e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
    e.keys('ix :: In')
    local words = menu()
    assert.is_true(vim.tbl_contains(words, 'Int'))
    assert.is_true(vim.tbl_contains(words, 'Integer'))
    assert.equals(-1, e.exec('return completion.info().selected'))
    select_item('Int')
    e.keys('<CR>')
    e.wait([[return vim.fn.getline(1) == 'x :: Int']])
    assert.equals(1, e.exec('return vim.api.nvim_buf_line_count(0)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
    assert.equals(0, e.exec('return completion.visible()'))
  end)

  it('recollects dynamic local snippets on a manual trigger at the same prefix', function()
    open('src/App/Before.hs')
    e.keys('imod')
    assert.same({ 'module' }, menu())
    assert.is_true(e.exec([[return completion.info().items[1].user_data.local_snippet:find('module App.Before where',1,true) ~= nil]]))
    e.exec('vim.api.nvim_buf_set_name(0, ...)', root .. '/src/App/After.hs')
    e.keys('<C-Space>')
    menu()
    e.wait([[return completion.info().items[1].user_data.local_snippet:find('module App.After where',1,true) ~= nil]])
    assert.equals('mod', e.exec('return vim.fn.getline(1)'))
  end)

  it('preserves Neovim digraph, signature and non-completion control keys', function()
    local query = [[
      local maps = {}
      for _, key in ipairs({ '<C-k>', '<C-s>', '<C-b>', '<C-f>' }) do
        local map = vim.fn.maparg(key, 'i', false, true)
        maps[key] = { rhs = map.rhs, expr = map.expr, desc = map.desc, callback = tostring(map.callback) }
      end
      return maps
    ]]
    local before = e.exec(query)
    e.keys('i')
    e.wait([[local map = vim.fn.maparg('<Tab>','i',false,true); return map.desc ~= nil and map.desc:find('blink.cmp',1,true) ~= nil]])
    assert.same(before, e.exec(query))
  end)

  it('keeps autopairs newlines and behaves normally without completion sources', function()
    e.keys('i(<CR>')
    e.wait('return vim.api.nvim_buf_line_count(0) == 3')
    assert.equals('(', e.exec('return vim.fn.getline(1)'))
    assert.equals(')', e.exec('return vim.fn.getline(3)'))
    e.keys('<Esc>')
    e.exec([[vim.cmd.enew({ bang = true }); vim.v.errmsg = '' ]])
    e.keys('ihello<C-Space>')
    e.wait([[return vim.fn.getline(1) == 'hello']])
    assert.equals('', e.exec('return vim.v.errmsg'))
  end)
end)
