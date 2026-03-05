local M = {}

function M.write_file(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines or { '' }, path)
end

function M.with_temp_project(files, run)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')

  for rel, content in pairs(files) do
    M.write_file(root .. '/' .. rel, content)
  end

  local cwd = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(root))

  local ok_run, err_run = pcall(run, root)
  local ok_cd, err_cd = pcall(vim.cmd, 'cd ' .. vim.fn.fnameescape(cwd))
  local ok_rm_call, rm_result = pcall(vim.fn.delete, root, 'rf')
  local ok_rm = ok_rm_call and rm_result == 0

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
    table.insert(
      failures,
      'cleanup failed (delete temp project): '
        .. (ok_rm_call and ('delete() returned ' .. tostring(rm_result)) or tostring(rm_result))
    )
  end

  error(table.concat(failures, '\n'), 0)
end

return M
