local keys = require('helpers.keys')

local function press_and_wait_for_line(lhs, expected_line)
  keys.press(lhs)
  local moved = vim.wait(1000, function()
    return vim.api.nvim_win_get_cursor(0)[1] == expected_line
  end, 20)
  assert(moved, ('expected cursor to jump to line %d'):format(expected_line))
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

describe('diagnostics', function()
  it(']c and [c jump between diagnostics and expose diagnostic messages at destination', function()
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

    press_and_wait_for_line(']c', 4)
    assert(string.match(message_at_cursor() or '', 'diag two') ~= nil, 'expected diagnostic message "diag two"')

    press_and_wait_for_line('[c', 1)
    assert(string.match(message_at_cursor() or '', 'diag one') ~= nil, 'expected diagnostic message "diag one"')

    keys.press('j')
    vim.wait(300, function()
      return count_floating_windows() == 0
    end, 25)
    assert(count_floating_windows() == 0, 'expected no floating diagnostic windows after cursor move')
  end)
end)
