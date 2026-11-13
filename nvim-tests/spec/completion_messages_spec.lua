local editor = require('helpers.editor')
local ui = require('helpers.ui')

describe('empty completion results', function()
  local e, screen

  before_each(function()
    e = editor.start()
    e.exec('completion = require("helpers.completion"); vim.g.haskell_tools = { hls = { auto_attach = false }, tools = { tags = { enable = false } } }; vim.bo.filetype = "haskell"')
    if vim.env.NVIM_COMPLETION_DIAGNOSTICS == "1" then e.exec("vim.opt.shortmess:remove('c')") end
    screen = ui.attach(e, 60, 8)
  end)

  after_each(function()
    if screen then screen.close(); screen = nil end
    if e then e.close(); e = nil end
  end)

  local function assert_quiet()
    screen.sync()
    assert.is_true(#screen.frames > 0)
    for index, frame in ipairs(screen.frames) do
      assert.equals('', vim.trim(frame.message), 'completion text in flushed frame ' .. index)
    end
    assert.equals(0, e.exec('return completion.visible()'))
    assert.equals('', e.exec('return vim.v.errmsg'))
  end

  it('stays quiet when automatic and manual local completion have no matches', function()
    e.keys('i')
    e.wait('return vim.api.nvim_get_mode().mode == "i"')
    screen.sync()
    screen.frames = {}
    e.keys('qqqz')
    e.wait([[return vim.fn.getline(1) == 'qqqz']])
    vim.wait(150)
    e.keys('<C-Space>')
    vim.wait(150)
    assert_quiet()
  end)

  for _, result in ipairs({ 'empty', 'nil' }) do
    it('stays quiet after automatic and manual ' .. result .. ' LSP replies', function()
      e.exec([[
        response_kind = ...
        replies = 0
        server = require('helpers.lsp').server({
          textDocumentSync = 1,
          completionProvider = { triggerCharacters = { '.' } },
        }, {
          ['textDocument/completion'] = function(_, respond)
            replies = replies + 1
            if response_kind == 'nil' then respond(nil)
            else respond({ isIncomplete = true, items = {} }) end
          end,
        })
        client_id = vim.lsp.start({ name = 'empty-completion-fixture', cmd = server.cmd })
      ]], result)
      e.wait('return vim.lsp.get_client_by_id(client_id).initialized')
      e.keys('i')
      e.wait('return vim.api.nvim_get_mode().mode == "i"')
      screen.sync()
      screen.frames = {}
      for char in ('qqqz'):gmatch('.') do
        e.exec('replies = 0')
        e.keys(char)
        e.wait('return replies > 0')
        vim.wait(100)
      end
      e.exec('replies = 0')
      e.keys('<C-Space>')
      e.wait('return replies > 0')
      vim.wait(100)
      assert_quiet()
    end)
  end
end)
