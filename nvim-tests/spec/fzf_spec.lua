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

local function grep_output(root, query)
  local opts = require('fzf-lua.config').normalize_opts({}, 'grep')
  local cmd = require('fzf-lua.make_entry').get_grep_cmd(opts, query, true)
  local result = vim.system({ 'sh', '-c', cmd }, { cwd = root, text = true }):wait(5000)
  assert.equals(0, result.code, result.stderr)
  return result.stdout
end

describe('fzf', function()
  it('searches leading-hyphen text in hidden files while excluding Git metadata', function()
    fs.with_temp_project({
      ['.hidden/build.txt'] = { '-Xfatal-warnings' },
      ['.git/review-marker'] = { '-Xfatal-warnings' },
    }, function(root)
      local output = grep_output(root, '-Xfatal-warnings')
      assert(output:find('.hidden/build.txt', 1, true), 'expected a match in the hidden file')
      assert(not output:find('review-marker', 1, true), 'expected Git metadata to be excluded')
    end)
  end)

  it('limits long matching lines without losing ordinary matches', function()
    fs.with_temp_project({
      ['short.txt'] = { 'needle' },
      ['long.txt'] = { 'needle ' .. string.rep('x', 10000) },
    }, function(root)
      local output = grep_output(root, 'needle')
      assert(output:find('short.txt', 1, true), 'expected the ordinary match')
      assert(#output < 1000, 'expected long matching lines to be omitted from picker output')
    end)
  end)

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

  it('initially selects the current file even when opened by absolute path', function()
    fs.with_temp_project({
      ['.first.txt'] = { 'root file' },
      ["src/near by/Current's file.txt"] = { 'current' },
      ['src/near by/Other.txt'] = { 'neighbor' },
      ['elsewhere/Distant.txt'] = { 'distant' },
    }, function(root)
      local current = root .. "/src/near by/Current's file.txt"
      vim.cmd('edit ' .. vim.fn.fnameescape(current))
      assert.equals(current, vim.fn.expand('%'))
      force_close_fzf_picker()

      keys.press('<C-p>')
      local ready = vim.wait(5000, function()
        return fzf_terminal_contains("Current's file.txt")
          and fzf_terminal_contains('.first.txt')
      end, 50)
      if not ready then force_close_fzf_picker() end
      assert(ready, 'expected the unfiltered picker to contain local and root files')

      assert(send_to_fzf_terminal('\r'), 'expected to accept the initial selection')
      local closed = vim.wait(3000, function()
        return not has_fzf_terminal_window()
      end, 50)
      if not closed then force_close_fzf_picker() end
      assert(closed, 'expected Enter to close the picker')
      assert.equals(vim.uv.fs_realpath(current), vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)))
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
