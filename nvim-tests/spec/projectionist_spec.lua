local fs = require('helpers.fs')

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
    fs.with_temp_project({
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
