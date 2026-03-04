-- Test bootstrap that loads the real user init.lua from this repo.

local this_file = debug.getinfo(1, 'S').source:sub(2)
local tests_root = vim.fs.dirname(this_file)
local repo_root = vim.fs.dirname(tests_root)
local nvim_root = repo_root .. '/nvim/.config/nvim'
local user_config_root = vim.fs.normalize(vim.fn.stdpath('config'))

local function is_under(path, root)
  local p = vim.fs.normalize(path)
  local r = vim.fs.normalize(root)
  return p == r or p:sub(1, #r + 1) == (r .. '/')
end

local function filter_paths(paths, blocked_root)
  local out = {}
  for _, path in ipairs(paths) do
    if not is_under(path, blocked_root) then
      table.insert(out, path)
    end
  end
  return out
end

local runtimepath = filter_paths(vim.opt.runtimepath:get(), user_config_root)
table.insert(runtimepath, 1, nvim_root)
table.insert(runtimepath, nvim_root .. '/after')
vim.opt.runtimepath = runtimepath

local packpath = filter_paths(vim.opt.packpath:get(), user_config_root)
vim.opt.packpath = packpath

local lua_dir = nvim_root .. '/lua'
package.path = table.concat({
  lua_dir .. '/?.lua',
  lua_dir .. '/?/init.lua',
  tests_root .. '/?.lua',
  tests_root .. '/?/init.lua',
  package.path,
}, ';')

-- Mark test mode for conditional config if needed.
vim.g.dotfiles_test_mode = true

-- Load the actual user config.
dofile(nvim_root .. '/init.lua')
