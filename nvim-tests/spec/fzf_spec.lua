local fs = require('helpers.fs')
local keys = require('helpers.keys')

local function get_fzf_terminal_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fzf' and vim.bo[buf].buftype == 'terminal' then
      return buf
    end
  end
end

local function has_fzf_terminal_window()
  return get_fzf_terminal_buf() ~= nil
end

local function force_close_fzf_picker()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fzf' and vim.bo[buf].buftype == 'terminal' then
      pcall(vim.api.nvim_win_close, win, true)
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

local function send_ctrl_p_to_fzf_terminal()
  local buf = get_fzf_terminal_buf()
  if buf then
    local ok_job, job_id = pcall(vim.api.nvim_buf_get_var, buf, 'terminal_job_id')
    if ok_job and job_id then
      vim.api.nvim_chan_send(job_id, '\x10')
      return true
    end
  end
  return false
end

local function send_to_fzf_terminal(chars)
  local buf = get_fzf_terminal_buf()
  if buf then
    local ok_job, job_id = pcall(vim.api.nvim_buf_get_var, buf, 'terminal_job_id')
    if ok_job and job_id then
      vim.api.nvim_chan_send(job_id, chars)
      return true
    end
  end
  return false
end

local function fzf_terminal_contains(text)
  local buf = get_fzf_terminal_buf()
  if not buf then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, '\n'):find(text, 1, true) ~= nil
end

describe('fzf', function()
  it('opens picker on <C-p> and closes on second Ctrl-p', function()
    fs.with_temp_project({
      ['src/User.txt'] = { 'hello' },
      ['src/Other.txt'] = { 'hello' },
    }, function(root)
      vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/src/User.txt'))
      force_close_fzf_picker()

      keys.press('<C-p>')

      local opened = vim.wait(5000, function()
        return has_fzf_terminal_window()
      end, 50)
      assert(opened, 'expected <C-p> to open fzf picker window')

      local sent = send_ctrl_p_to_fzf_terminal()
      assert(sent, 'expected to find fzf terminal job for second Ctrl-p')

      local closed = vim.wait(3000, function()
        return not has_fzf_terminal_window()
      end, 50)
      if not closed then
        force_close_fzf_picker()
      end

      assert(closed, 'expected second Ctrl-p to close fzf picker window')
    end)
  end)

  it('keeps multi-select quickfix behavior', function()
    fs.with_temp_project({
      ['src/current.txt'] = { 'hello' },
      ['pick_me_one.txt'] = { 'one' },
      ['pick_me_two.txt'] = { 'two' },
    }, function(root)
      vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/src/current.txt'))
      force_close_fzf_picker()
      vim.fn.setqflist({}, 'r')

      keys.press('<C-p>')

      local opened = vim.wait(5000, function()
        return has_fzf_terminal_window()
      end, 50)
      assert(opened, 'expected <C-p> to open fzf picker window')

      local sent = send_to_fzf_terminal('pick_me_')
      assert(sent, 'expected to send the filter query to the fzf terminal job')

      local filtered = vim.wait(5000, function()
        return fzf_terminal_contains('pick_me_one.txt')
          and fzf_terminal_contains('pick_me_two.txt')
      end, 50)
      assert(filtered, 'expected fzf picker to show both matching files before multi-select')

      sent = send_to_fzf_terminal('\x11')
      assert(sent, 'expected to send multi-select accept to fzf terminal job')

      local quickfix_populated = vim.wait(5000, function()
        local qf = vim.fn.getqflist()
        if #qf ~= 2 then
          return false
        end

        local names = {}
        for _, item in ipairs(qf) do
          local filename = item.filename
          if (not filename or filename == '') and item.bufnr and item.bufnr > 0 then
            filename = vim.api.nvim_buf_get_name(item.bufnr)
          end
          table.insert(names, vim.fn.fnamemodify(filename, ':t'))
        end
        table.sort(names)

        return names[1] == 'pick_me_one.txt' and names[2] == 'pick_me_two.txt'
      end, 50)

      assert(quickfix_populated, 'expected multi-select to populate quickfix with selected files')
    end)
  end)
end)
