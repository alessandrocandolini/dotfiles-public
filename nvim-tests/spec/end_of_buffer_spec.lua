local editor = require('helpers.editor')

describe('end of buffer', function()
  local e

  before_each(function()
    e = editor.start()
  end)

  after_each(function()
    if e then e.close() end
  end)

  it('renders the lines past the end of the buffer blank instead of with tildes', function()
    local cells = e.exec([[
      vim.cmd.enew()
      vim.cmd.redraw({ bang = true })
      local top, left = unpack(vim.fn.win_screenpos(0))
      local cells = {}
      for row = top + 1, top + vim.fn.winheight(0) - 1 do
        cells[#cells + 1] = vim.fn.screenstring(row, left)
      end
      return cells
    ]])

    assert.is_true(#cells > 0)
    for _, cell in ipairs(cells) do
      assert.equals(' ', cell)
    end
  end)
end)
