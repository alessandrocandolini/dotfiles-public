local editor = require('helpers.editor')

describe('captured rust-analyzer completion', function()
  local e

  after_each(function()
    if e then e.close(); e = nil end
  end)

  local function check_completion(height, reopen)
    local fixture = vim.json.decode(table.concat(vim.fn.readfile('nvim-tests/fixtures/rust_analyzer_file.json'), '\n'))
    e = editor.start()
    e.resize(100, height)
    e.exec([[
      local fixture = ...
      completion = require('helpers.completion')
      vim.lsp.enable('rust-analyzer', false)
      vim.bo.filetype = 'rust'
      local lines = vim.deepcopy(fixture.lines)
      lines[2] = lines[2]:sub(1, 12)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { 2, 11 })
      resolved_file = false
      server = require('helpers.lsp').server({
        textDocumentSync = 1,
        completionProvider = { resolveProvider = true },
      }, {
        ['textDocument/completion'] = function(params, respond)
          local items = vim.deepcopy(fixture.items)
          for _, item in ipairs(items) do
            item.textEdit.insert['end'] = params.position
            item.textEdit.replace['end'] = params.position
            item.data = item.label
          end
          respond({ isIncomplete = fixture.isIncomplete, items = items })
        end,
        ['completionItem/resolve'] = function(item, respond)
          if item.label == 'File' then
            resolved_file = true
            item.additionalTextEdits = { {
              range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
              newText = 'use std::fs::File;\n\n',
            } }
          end
          respond(item)
        end,
      })
      client_id = vim.lsp.start({ name = 'rust-analyzer-capture', cmd = server.cmd })
    ]], fixture)
    e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
    e.keys('AFile')
    e.wait([[
      local first = completion.info().items[1]
      return completion.visible() == 1 and first and first.text_edit.insert['end'].character == 16
    ]])
    local popup = e.exec([[
      local win = require('cmp').core.view.custom_entries_view.entries_win.win
      return { height = vim.api.nvim_win_get_height(win), row = vim.api.nvim_win_get_config(win).row }
    ]])
    assert.is_true(popup.height > 0 and popup.row + popup.height <= height)
    if height == 35 then assert.is_true(popup.height > 8) end
    assert.equals('File', e.exec('return completion.info().items[1].word'))
    assert.equals(-1, e.exec('return completion.info().selected'))
    assert.same(fixture.lines, e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
    e.keys('<Tab>')
    e.wait('return completion.info().selected == 0')
    if reopen then
      for _, rows in ipairs({ 6, 35, 13, 35 }) do
        e.resize(100, rows)
        e.keys('<Esc>')
        e.wait([[return vim.api.nvim_get_mode().mode == 'n' and completion.visible() == 0]])
        e.keys('a<C-Space>')
        e.wait([[return completion.visible() == 1 and completion.info().items[1].word == 'File']])
        assert.equals(-1, e.exec('return completion.info().selected'))
        e.keys('<Tab>')
        e.wait('return completion.info().selected == 0')
        e.wait([[
          local view = require('cmp').core.view.custom_entries_view
          if not view:visible() then return false end
          local win = view.entries_win.win
          local cfg = vim.api.nvim_win_get_config(win)
          local height = vim.api.nvim_win_get_height(win)
          return height > 0 and cfg.row + height <= vim.o.lines
            and (vim.o.lines < 35 or height > 8)
        ]])
        assert.equals(0, e.exec('return completion.info().selected'))
        assert.same(fixture.lines, e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
      end
    end
    e.keys('<CR>')
    e.wait([[return completion.visible() == 0 and vim.fn.getline(1) == 'use std::fs::File;']])
    assert.same({ 'use std::fs::File;', '', 'fn main() {', '    let f = File', '}' },
      e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
    assert.is_true(e.exec('return resolved_file'))
  end

  for _, height in ipairs({ 35, 13, 6 }) do
    it('ranks File first and imports only after selection in a ' .. height .. '-row window', function()
      check_completion(height, false)
    end)
  end

  it('fits the popup to the pane when reopened after resizing', function()
    check_completion(35, true)
  end)
end)
