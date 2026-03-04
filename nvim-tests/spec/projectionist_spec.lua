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

local function normalize_path(path)
  return (path:gsub('^/private', ''))
end

local function leader_lhs(keys)
  local leader = vim.g.mapleader
  if type(leader) ~= 'string' or leader == '' then
    leader = '\\'
  end
  return leader .. keys
end

describe('projectionist', function()
  it('<leader>gt jumps to alternate and <leader>gt again jumps back', function()
    with_temp_project({
      ['stack.yaml'] = {
        'resolver: lts-22.34',
        'packages:',
        '  - .',
      },
      ['src/User.hs'] = { 'module User where' },
      ['test/UserSpec.hs'] = { 'module UserSpec where' },
    }, function(root)
      package.loaded['config.projectionist'] = nil
      require('config.projectionist').setup()

      local src = root .. '/src/User.hs'
      local spec = root .. '/test/UserSpec.hs'

      vim.cmd('edit ' .. vim.fn.fnameescape(src))
      assert(
        normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(src),
        'expected to start in source file'
      )

      press(leader_lhs('gt'))
      assert(
        normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(spec),
        'expected <leader>gt to jump to spec file'
      )

      press(leader_lhs('gt'))
      assert(
        normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(src),
        'expected second <leader>gt to jump back to source file'
      )
    end)
  end)
end)
