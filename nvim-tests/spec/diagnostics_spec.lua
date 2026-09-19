local keys = require('helpers.keys')

local function floating_windows()
  local windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative and cfg.relative ~= '' then
      windows[#windows + 1] = win
    end
  end
  return windows
end

local function press_and_wait_for_diagnostic(lhs, expected_line, expected_message)
  local source_win = vim.api.nvim_get_current_win()
  keys.press(lhs)
  assert(vim.wait(1000, function()
    return vim.api.nvim_win_get_cursor(source_win)[1] == expected_line
  end, 20), ('expected cursor to jump to line %d'):format(expected_line))

  assert(vim.wait(1000, function()
    local windows = floating_windows()
    if #windows ~= 1 then
      return false
    end
    local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(windows[1]), 0, -1, false)
    return table.concat(lines, '\n'):find(expected_message, 1, true) ~= nil
  end, 20), ('expected one floating window showing %q'):format(expected_message))
  assert(vim.api.nvim_get_current_win() == source_win, 'diagnostic float must not take focus')
end

describe('diagnostics', function()
  it(']c and [c show diagnostic floats without taking focus and close them on movement', function()
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

    press_and_wait_for_diagnostic(']c', 4, 'diag two')
    press_and_wait_for_diagnostic('[c', 1, 'diag one')

    keys.press('j')
    assert(vim.api.nvim_win_get_cursor(0)[1] == 2, 'expected j to move off the diagnostic')
    -- Headless feedkeys moves the cursor without dispatching CursorMoved.
    vim.api.nvim_exec_autocmds('CursorMoved', { buffer = 0 })
    assert(vim.wait(1000, function()
      return #floating_windows() == 0
    end, 20), 'expected no floating diagnostic windows after cursor move')
  end)
end)
