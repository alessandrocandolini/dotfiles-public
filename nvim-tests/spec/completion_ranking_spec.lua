local editor = require('helpers.editor')

describe('completion ranking and imports', function()
  local e

  after_each(function()
    if e then e.close(); e = nil end
  end)

  for _, filetype in ipairs({ 'rust', 'haskell', 'scala' }) do
    for _, incomplete in ipairs({ false, true }) do
      it('ranks an exact match first in ' .. filetype .. ' with isIncomplete=' .. tostring(incomplete), function()
        e = editor.start()
        e.exec([[
          completion = require('helpers.completion')
          local filetype, incomplete = ...
          vim.lsp.enable('rust-analyzer', false)
          vim.g.haskell_tools = { hls = { auto_attach = false }, tools = { tags = { enable = false } } }
          vim.bo.filetype = filetype
          vim.api.nvim_buf_set_lines(0, 0, -1, false, { '', '' })
          vim.api.nvim_win_set_cursor(0, { 2, 0 })
          resolved = {}
          server = require('helpers.lsp').server({
            textDocumentSync = 1,
            completionProvider = { resolveProvider = true },
          }, {
            ['textDocument/completion'] = function(params, respond)
              local items = {}
              for index = 1, 16 do
                local label = index == 16 and 'File' or 'FileAlternative' .. index
                items[index] = {
                  label = label,
                  kind = 7,
                  sortText = string.format('%03d', index),
                  preselect = index == 1,
                  data = { import = label },
                  textEdit = {
                    range = {
                      start = { line = params.position.line, character = 0 },
                      ['end'] = params.position,
                    },
                    newText = label,
                  },
                }
              end
              respond({ isIncomplete = incomplete, items = items })
            end,
            ['completionItem/resolve'] = function(item, respond)
              resolved[item.label] = true
              if item.label == 'File' then
                item.additionalTextEdits = { {
                  range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
                  newText = 'import File\n',
                } }
              end
              respond(item)
            end,
          })
          client_id = vim.lsp.start({ name = 'ranking-fixture', cmd = server.cmd })
        ]], filetype, incomplete)
        e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
        e.keys('iFi')
        e.wait('return completion.visible() == 1 and #completion.info().items == 16')
        e.keys('le')
        e.wait([[return vim.fn.getline(2) == 'File' and completion.info().items[1].word == 'File']])
        assert.equals(-1, e.exec('return completion.info().selected'))
        assert.equals('', e.exec('return vim.fn.getline(1)'))
        e.keys('<Tab>')
        e.wait('return completion.info().selected == 0')
        e.keys('<CR>')
        e.wait([[return vim.fn.getline(1) == 'import File' and completion.visible() == 0]])
        assert.same({ 'import File', '', 'File' }, e.exec('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'))
        assert.is_true(e.exec('return resolved.File == true'))
      end)
    end
  end
end)
