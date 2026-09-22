local editor = require('helpers.editor')
local fs = require('helpers.fs')

describe('native completion and snippets', function()
  local e, root

  local function open(path)
    e.exec('vim.cmd.edit(vim.fn.fnameescape(...))', root .. '/' .. path)
  end

  local function menu()
    e.wait('return vim.fn.pumvisible() == 1')
    return e.exec([[return vim.tbl_map(function(item) return item.word end, vim.fn.complete_info().items)]])
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
    e.wait([[return vim.tbl_contains(vim.tbl_map(function(i) return i.word end, vim.fn.complete_info().items), 'iterate')]])
  end

  before_each(function()
    root = vim.fn.tempname()
    fs.write_file(root .. '/src/App/Main.hs', { '' })
    fs.write_file(root .. '/test/App/MainSpec.hs', { '' })
    e = editor.start()
    -- Exercise the real Haskell ftplugin, without launching an external HLS.
    e.exec('vim.g.haskell_tools = { hls = { auto_attach = false } }')
    open('src/App/Main.hs')
  end)

  after_each(function()
    if e then e.close() end
    vim.fn.delete(root, 'rf')
  end)

  it('offers and expands local snippets without any LSP or completion plugins', function()
    assert.equals(0, e.exec('return #vim.lsp.get_clients()'))
    assert.is_true(e.exec([[return package.loaded.cmp == nil and package.loaded.luasnip == nil]]))
    e.keys('iit')
    assert.same({ 'it' }, menu())
    e.keys('<CR>')
    e.wait('return vim.snippet.active()')
    assert.equals('it "description" $', e.exec('return vim.fn.getline(1)'))
    e.keys('example<C-k>')
    e.wait([[return vim.fn.getline(1) == 'it "example" $' and vim.api.nvim_win_get_cursor(0)[1] == 2]])
    local actual_col = e.exec('return vim.api.nvim_win_get_cursor(0)[2]')
    e.keys('<C-k>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] > ' .. actual_col)
    e.keys('<C-j>')
    e.wait('return vim.api.nvim_win_get_cursor(0)[2] == ' .. actual_col)
  end)

  it('generates the right source and test module headers from the filename', function()
    e.keys('imod')
    assert.same({ 'module' }, menu())
    e.keys('<CR>')
    e.wait([[return vim.fn.getline(1) == 'module App.Main where']])
    assert.same({ 'module App.Main where', '', '' }, e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
    e.keys('<Esc>')
    e.exec('vim.bo.modified = false')
    open('test/App/MainSpec.hs')
    e.keys('imod')
    assert.same({ 'module' }, menu())
    e.keys('<CR>')
    e.wait([[return vim.fn.getline(1) == 'module App.MainSpec where']])
    assert.equals('import Test.Hspec', e.exec('return vim.fn.getline(3)'))
    assert.equals('spec = do', e.exec('return vim.fn.getline(8)'))
  end)

  it('keeps local results while a late-attaching LSP completes asynchronously', function()
    e.keys('iit')
    assert.same({ 'it' }, menu())
    start_server()
    e.keys('<C-Space>')
    e.wait('return #pending > 0')
    assert.same({ 'it' }, menu())
    reply()
    assert.equals(2, #menu())
    e.keys('<C-e>')
    e.wait('return vim.fn.pumvisible() == 0')
    assert.equals('it', e.exec('return vim.fn.getline(1)'))
    assert.is_false(e.exec('return vim.snippet.active()'))
  end)

  it('expands a local result from the mixed menu using Enter', function()
    start_server()
    e.keys('iit')
    menu()
    reply()
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
    e.wait('return vim.fn.complete_info().selected == 0')
    reply()
    assert.equals('it', e.exec([[
      local info = vim.fn.complete_info()
      return info.items[info.selected + 1] and info.items[info.selected + 1].word
    ]]))
  end)

  it('accepts an LSP snippet, resolves its import, and uses the same jump keys', function()
    start_server()
    e.exec([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { '', '', '' }); vim.api.nvim_win_set_cursor(0, { 3, 0 })]])
    e.keys('iit')
    menu()
    reply()
    e.keys('<Tab><Tab><CR>')
    e.wait([[return vim.fn.getline(1) == 'import Probe' and vim.snippet.active()]])
    assert.equals('iterate(value)', e.exec('return vim.fn.getline(4)'))
    e.keys('argument<C-k>')
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

  it('can expand the exact local trigger with Ctrl-K and undo the expansion', function()
    e.keys('iprop')
    menu()
    e.keys('<C-k>')
    e.wait('return vim.snippet.active()')
    assert.equals('prop "description" $', e.exec('return vim.fn.getline(1)'))
    e.keys('<Esc>u')
    e.wait([[return not vim.fn.getline(1):find('description', 1, true)]])
    assert.equals(1, e.exec('return vim.api.nvim_buf_line_count(0)'))
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
