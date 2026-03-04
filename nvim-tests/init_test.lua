-- Test bootstrap that loads the real user init.lua from this repo.

local this_file = debug.getinfo(1, 'S').source:sub(2)
local tests_root = vim.fs.dirname(this_file)
local repo_root = vim.fs.dirname(tests_root)
local nvim_root = repo_root .. '/nvim/.config/nvim'

vim.opt.runtimepath:prepend(nvim_root)

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
