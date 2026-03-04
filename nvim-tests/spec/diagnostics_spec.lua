local assertx = require('helpers.assert')

local function press(lhs)
  local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
  vim.api.nvim_feedkeys(keys, 'mx', false)
end

local function message_at_cursor()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diags = vim.diagnostic.get(0, { lnum = lnum })
  if #diags == 0 then
    return nil
  end
  return diags[1].message
end

local function count_floating_windows()
  local count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative and cfg.relative ~= '' then
      count = count + 1
    end
  end
  return count
end

return {
  [']c and [c jump between diagnostics and expose diagnostic messages at destination'] = function()
    package.loaded['config.diagnostics'] = nil
    require('config.diagnostics').setup()

    vim.cmd('enew')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'line 1',
      'line 2',
      'line 3',
      'line 4',
      'line 5',
    })

    local ns = vim.api.nvim_create_namespace('tests_diagnostics_behavior')
    vim.diagnostic.set(ns, 0, {
      {
        lnum = 0,
        col = 0,
        severity = vim.diagnostic.severity.ERROR,
        message = 'diag one',
      },
      {
        lnum = 3,
        col = 0,
        severity = vim.diagnostic.severity.WARN,
        message = 'diag two',
      },
    })

    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    press(']c')
    assertx.expect(vim.api.nvim_win_get_cursor(0)[1]).to_equal(4)
    assertx.expect(message_at_cursor()).to_match('diag two')

    press('[c')
    assertx.expect(vim.api.nvim_win_get_cursor(0)[1]).to_equal(1)
    assertx.expect(message_at_cursor()).to_match('diag one')

    -- Diagnostic float should close when cursor moves.
    press('j')
    vim.wait(300, function()
      return count_floating_windows() == 0
    end, 25)
    assertx.expect(count_floating_windows()).to_equal(0)
  end,
}
