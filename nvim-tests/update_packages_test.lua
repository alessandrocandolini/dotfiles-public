-- Regression checks using the real CLI, a local Git source, and a build fixture.
local repo, root = vim.fn.getcwd(), vim.fn.tempname()
local config, source = root .. '/config/nvim', root .. '/source'
local lock_path = config .. '/nvim-pack-lock.json'
local installed = root .. '/data/nvim/site/pack/core/opt/build-fixture'

local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(contents, '\n'), path, 'b')
end

local function read(path)
  return table.concat(vim.fn.readfile(path, 'b'), '\n')
end

local function git(args, cwd)
  local result = vim.system(vim.list_extend({ vim.fn.exepath('git') }, args), {
    cwd = cwd or source, text = true,
  }):wait(10000)
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end

local function commit(version)
  write(source .. '/version', version .. '\n')
  git({ 'add', '.' })
  git({ '-c', 'user.name=Test', '-c', 'user.email=test@example.com', '-c', 'commit.gpgsign=false',
    '-c', 'core.hooksPath=/dev/null', 'commit', '-m', version })
  return git({ 'rev-parse', 'HEAD' })
end

local function invoke(mode, success)
  local result = vim.system({ vim.v.progpath, '--headless', '-u', 'NONE', '-i', 'NONE', '-l',
    repo .. '/scripts/nvim-pack.lua', mode, config }, {
    cwd = root, text = true,
    env = {
      HOME = root .. '/home', XDG_CONFIG_HOME = root .. '/config', XDG_DATA_HOME = root .. '/data',
      XDG_STATE_HOME = root .. '/state', XDG_CACHE_HOME = root .. '/cache', NVIM_APPNAME = 'nvim',
      NVIM_LOG_FILE = root .. '/nvim.log', PATH = root .. '/bin',
      HOOK_FAIL = root .. '/fail', HOOK_MARKER = root .. '/hooks',
    },
  }):wait(30000)
  assert(result.code ~= 124 and (result.code == 0) == success,
    mode .. ': unexpected exit ' .. result.code .. '\n' .. result.stdout .. result.stderr)
end

local ok, err = xpcall(function()
  vim.fn.mkdir(source, 'p')
  git({ 'init', '-b', 'main' })
  local old_rev = commit('old')
  local new_rev = commit('new')
  write(config .. '/lua/config/vimpack.lua', string.format([[
local M = dofile(%q)
M.specs = {{ name = 'build-fixture', src = %q, optional = true }}
M.build_hooks = { ['build-fixture'] = { 'build-hook' } }
return M
]], repo .. '/nvim/.config/nvim/lua/config/vimpack.lua', 'file://' .. source))
  local lock = { plugins = { ['build-fixture'] = { src = 'file://' .. source, rev = old_rev } } }
  local original = vim.json.encode(lock) .. '\n'
  write(lock_path, original)
  write(root .. '/bin/build-hook', '#!/bin/sh\nsleep 0.1\necho build >> "$HOOK_MARKER"\ntest ! -f "$HOOK_FAIL"\n')
  vim.fn.setfperm(root .. '/bin/build-hook', 'rwx------')
  for _, tool in ipairs({ 'git', 'sleep' }) do
    assert(vim.uv.fs_symlink(vim.fn.exepath(tool), root .. '/bin/' .. tool))
  end

  invoke('sync', true)
  assert(git({ 'rev-parse', 'HEAD' }, installed) == old_rev)
  assert(read(lock_path) == original)
  invoke('update', true)
  local updated = read(lock_path)
  assert(vim.json.decode(updated).plugins['build-fixture'].rev == new_rev)
  assert(git({ 'rev-parse', 'HEAD' }, installed) == old_rev)
  assert(read(root .. '/hooks') == 'build\n', 'update ran a build')
  commit('future')
  invoke('sync', true)
  assert(git({ 'rev-parse', 'HEAD' }, installed) == new_rev)
  assert(read(lock_path) == updated)
  print('PASS: update is isolated; sync applies locked revisions without rewriting the lockfile')

  write(root .. '/fail', '')
  invoke('sync', false)
  invoke('sync', false)
  assert(read(lock_path) == updated)
  assert(not vim.uv.fs_stat(root .. '/state/nvim/nvim-pack-sync'))
  vim.fn.delete(root .. '/fail')
  invoke('sync', true)
  assert(#vim.fn.readfile(root .. '/hooks') == 5, 'failed builds were not retried')
  print('PASS: failed builds fail sync and retry on unchanged checkouts')

  lock.plugins['build-fixture'].rev = string.rep('0', 40)
  local invalid = vim.json.encode(lock) .. '\n'
  write(lock_path, invalid)
  invoke('sync', false)
  assert(read(lock_path) == invalid, 'failed sync rewrote the source lockfile')
  print('PASS: failed checkouts preserve the lockfile')
end, debug.traceback)

vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
