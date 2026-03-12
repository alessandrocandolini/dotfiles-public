local fs = require('helpers.fs')
local keys = require('helpers.keys')

local function normalize_path(path)
  return (path:gsub('^/private', ''))
end

local function leader_lhs(rhs)
  local leader = vim.g.mapleader
  if type(leader) ~= 'string' or leader == '' then
    leader = '\\'
  end
  return leader .. rhs
end

local function wait_for_buffer(path)
  local ok = vim.wait(1000, function()
    return normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(path)
  end, 20)
  assert(ok, ('expected current buffer to become %s'):format(path))
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
      local src = root .. '/src/User.hs'
      local spec = root .. '/test/UserSpec.hs'

      vim.cmd('edit ' .. vim.fn.fnameescape(src))
      assert(
        normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(src),
        'expected to start in source file'
      )

      keys.press(leader_lhs('gt'))
      wait_for_buffer(spec)

      keys.press(leader_lhs('gt'))
      wait_for_buffer(src)
    end)
  end)

  it('jumps between play app and test files', function()
    fs.with_temp_project({
      ['build.sbt'] = { 'ThisBuild / scalaVersion := "2.13.16"' },
      ['conf/routes'] = { 'GET / controllers.HomeController.index()' },
      ['app/controllers/HomeController.scala'] = { 'package controllers' },
      ['test/controllers/HomeControllerSpec.scala'] = { 'package controllers' },
    }, function(root)
      local src = root .. '/app/controllers/HomeController.scala'
      local spec = root .. '/test/controllers/HomeControllerSpec.scala'

      vim.cmd('edit ' .. vim.fn.fnameescape(src))
      assert(
        normalize_path(vim.api.nvim_buf_get_name(0)) == normalize_path(src),
        'expected to start in play source file'
      )

      keys.press(leader_lhs('gt'))
      wait_for_buffer(spec)

      keys.press(leader_lhs('gt'))
      wait_for_buffer(src)
    end)
  end)
end)
