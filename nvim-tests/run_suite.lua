local SPEC_TIMEOUT_MS = 30000
local PROCESS_TIMEOUT_EXIT_CODE = 124

local function sorted_specs()
  local specs = vim.fn.globpath('nvim-tests/spec', '*_spec.lua', false, true)
  table.sort(specs)
  return specs
end

local function run_spec(spec)
  local cmd = {
    'nvim',
    '--headless',
    '-u',
    'nvim-tests/init_test.lua',
    '-c',
    string.format(
      "lua require('plenary.busted').run(%q, { minimal_init = 'nvim-tests/init_test.lua' })",
      spec
    ),
    '-c',
    'qa!',
  }

  local res = vim.system(cmd, { text = true }):wait(SPEC_TIMEOUT_MS)
  if res.stdout and res.stdout ~= '' then
    io.write(res.stdout)
  end
  if res.stderr and res.stderr ~= '' then
    io.stderr:write(res.stderr)
  end
  if res.code == PROCESS_TIMEOUT_EXIT_CODE then
    io.stderr:write(
      string.format('Spec timed out after %dms: %s\n', SPEC_TIMEOUT_MS, spec)
    )
  end
  return res.code
end

local status = 0
for _, spec in ipairs(sorted_specs()) do
  if run_spec(spec) ~= 0 then
    status = 1
  end
end

if status ~= 0 then
  vim.cmd('cquit 1')
else
  vim.cmd('qa!')
end
