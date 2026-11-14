local editor = require('helpers.editor')

describe('completion cancellation and queued input', function()
  local e

  before_each(function()
    e = editor.start()
    e.exec([[
      completion = require('helpers.completion')
      vim.g.haskell_tools = { hls = { auto_attach = false }, tools = { tags = { enable = false } } }
      vim.bo.filetype = 'haskell'
      vim.v.errmsg = ''
    ]])
  end)

  after_each(function()
    if e then e.close(); e = nil end
  end)

  local function select(selection, text)
    e.keys('i' .. (text or 'pr'))
    e.wait([[return completion.visible() == 1 and completion.info().items[1].word == 'prop']])
    if selection ~= '' then
      e.keys(selection)
      e.wait('return completion.info().selected == 0')
    end
    assert.equals(text or 'pr', e.exec('return vim.fn.getline(1)'))
  end

  for _, selection in ipairs({ '', '<Tab>', '<C-n>', '<C-p>' }) do
    it('runs dd in Normal mode after Escape with ' .. (selection == '' and 'no selection' or selection), function()
      select(selection)
      e.exec([[vim.api.nvim_input('<Esc>dd')]])
      e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == '']])
      assert.equals('pr\n', e.exec([[return vim.fn.getreg('"')]]))
      e.keys('iok<Esc>')
      e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == 'ok']])
      assert.equals('', e.exec('return vim.v.errmsg'))
    end)
  end

  for _, selection in ipairs({ '<C-n>', '<C-p>' }) do
    it('handles selection, Escape and dd together with ' .. selection, function()
      select('')
      e.exec('vim.api.nvim_input(...)', selection .. '<Esc>dd')
      e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == '']])
      assert.equals('pr\n', e.exec([[return vim.fn.getreg('"')]]))
      e.keys('iok<Esc>')
      e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == 'ok']])
      assert.equals('', e.exec('return vim.v.errmsg'))
    end)
  end

  it('leaves Insert mode before queued commands when no menu is open', function()
    e.keys('ihello')
    e.wait('return completion.visible() == 0')
    e.exec([[vim.api.nvim_input('<Esc>dd')]])
    e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == '']])
    assert.equals('hello\n', e.exec([[return vim.fn.getreg('"')]]))
    assert.equals('', e.exec('return vim.v.errmsg'))
  end)

  it('restores the prefix after a multibyte character before the next command', function()
    select('<C-n>', 'λ = pr')
    e.exec([[vim.api.nvim_input('<Esc>x')]])
    e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == 'λ = p']])
    assert.equals('r', e.exec([[return vim.fn.getreg('"')]]))
    assert.equals('', e.exec('return vim.v.errmsg'))
  end)

  it('keeps cancellation in the same undo block as typing', function()
    select('<C-n>')
    e.exec([[vim.api.nvim_input('<Esc>u')]])
    e.wait([[return vim.api.nvim_get_mode().mode == 'n' and vim.fn.getline(1) == '']])
    e.keys('<C-r>')
    e.wait([[return vim.fn.getline(1) == 'pr']])
    assert.equals('', e.exec('return vim.v.errmsg'))
  end)
end)
