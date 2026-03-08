-- Minimal bootstrap for tests: validate the real config path and load init.lua unchanged.

local this_file = debug.getinfo(1, 'S').source:sub(2)
local tests_root = vim.fs.dirname(this_file)
local repo_root = vim.fs.dirname(tests_root)
local repo_nvim_root = repo_root .. '/nvim/.config/nvim'
local config_root = vim.fs.normalize(vim.fn.stdpath('config'))
local data_root = vim.fs.normalize(vim.fn.stdpath('data'))

package.path = table.concat({
  tests_root .. '/?.lua',
  tests_root .. '/?/init.lua',
  package.path,
}, ';')

local function assert_true(ok, message)
  if not ok then
    error(message, 0)
  end
end

local function normalize(path)
  return vim.fs.normalize(path)
end

local function is_under(path, root)
  local normalized_path = normalize(path)
  local normalized_root = normalize(root)
  return normalized_path == normalized_root or normalized_path:sub(1, #normalized_root + 1) == (normalized_root .. '/')
end

local config_init = vim.fs.joinpath(config_root, 'init.lua')
local config_lockfile = vim.fs.joinpath(config_root, 'nvim-pack-lock.json')

assert_true(vim.fn.filereadable(config_init) == 1, 'Test bootstrap expected init.lua in stdpath("config")')
assert_true(
  normalize(config_root) == normalize(repo_nvim_root),
  'Test bootstrap expected stdpath("config") to be the repo Neovim config'
)
assert_true(
  vim.fn.filereadable(config_lockfile) == 1,
  'Test bootstrap expected nvim-pack-lock.json in stdpath("config")'
)
assert_true(
  not is_under(data_root, repo_root),
  'Test bootstrap expected stdpath("data") to stay outside the repo for ephemeral plugin installs'
)

-- Test helpers live outside stdpath("config"), but the actual config code should load from it unchanged.
dofile(config_init)
