local function write_file(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines or { '' }, path)
end

local function with_temp_project(files, run)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')

  for rel, content in pairs(files) do
    write_file(root .. '/' .. rel, content)
  end

  local cwd = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(root))

  local ok_run, err_run = pcall(run, root)
  local ok_cd, err_cd = pcall(vim.cmd, 'cd ' .. vim.fn.fnameescape(cwd))
  local ok_rm, err_rm = pcall(vim.fn.delete, root, 'rf')

  if ok_run and ok_cd and ok_rm then
    return
  end

  local failures = {}
  if not ok_run then
    table.insert(failures, 'run failed: ' .. tostring(err_run))
  end
  if not ok_cd then
    table.insert(failures, 'cleanup failed (restore cwd): ' .. tostring(err_cd))
  end
  if not ok_rm then
    table.insert(failures, 'cleanup failed (delete temp project): ' .. tostring(err_rm))
  end

  error(table.concat(failures, '\n'), 0)
end

local function press(lhs)
  local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
  vim.api.nvim_feedkeys(keys, 'mx', false)
end

local function has_fzf_terminal_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fzf' and vim.bo[buf].buftype == 'terminal' then
      return true
    end
  end
  return false
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
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fzf' and vim.bo[buf].buftype == 'terminal' then
      local ok_job, job_id = pcall(vim.api.nvim_buf_get_var, buf, 'terminal_job_id')
      if ok_job and job_id then
        vim.api.nvim_chan_send(job_id, '\x10')
        return true
      end
    end
  end
  return false
end

describe('fzf', function()
  it('opens picker on <C-p> and closes on second Ctrl-p', function()
    with_temp_project({
      ['src/User.txt'] = { 'hello' },
      ['src/Other.txt'] = { 'hello' },
    }, function(root)
      package.loaded['config.fzf'] = nil
      require('config.fzf').setup()

      vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/src/User.txt'))

      local wins_before = #vim.api.nvim_list_wins()
      press('<C-p>')

      local opened = vim.wait(5000, function()
        return #vim.api.nvim_list_wins() > wins_before and has_fzf_terminal_window()
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
end)
