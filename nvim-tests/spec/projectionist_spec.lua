local assertx = require('helpers.assert')

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

  local ok, err = pcall(run, root)
  local ok_cd, err_cd = pcall(vim.cmd, 'cd ' .. vim.fn.fnameescape(cwd))
  local ok_rm, err_rm = pcall(vim.fn.delete, root, 'rf')

  if not ok then
    error(err, 0)
  end
  if not ok_cd then
    error(err_cd, 0)
  end
  if not ok_rm then
    error(err_rm, 0)
  end
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

return {
  ['<leader>gt jumps to alternate and <leader>gt again jumps back'] = function()
    with_temp_project({
      ['stack.yaml'] = { 'name: test-project' },
      ['src/User.hs'] = { 'module User where' },
      ['test/UserSpec.hs'] = { 'module UserSpec where' },
    }, function(root)
      package.loaded['config.projectionist'] = nil
      require('config.projectionist').setup()

      local src = root .. '/src/User.hs'
      local spec = root .. '/test/UserSpec.hs'

      vim.cmd('edit ' .. vim.fn.fnameescape(src))
      assertx.expect(normalize_path(vim.api.nvim_buf_get_name(0))).to_equal(normalize_path(src))

      press(leader_lhs('gt'))
      assertx.expect(normalize_path(vim.api.nvim_buf_get_name(0))).to_equal(normalize_path(spec))

      press(leader_lhs('gt'))
      assertx.expect(normalize_path(vim.api.nvim_buf_get_name(0))).to_equal(normalize_path(src))
    end)
  end,
}
