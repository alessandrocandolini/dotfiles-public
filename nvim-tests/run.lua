local specs = {
  'spec.diagnostics_spec',
  'spec.fzf_spec',
  'spec.projectionist_spec',
}

local total = 0
local passed = 0
local failed = 0

for _, spec_name in ipairs(specs) do
  package.loaded[spec_name] = nil
  local ok_mod, mod_or_err = pcall(require, spec_name)
  if not ok_mod then
    failed = failed + 1
    io.stderr:write(string.format('FAIL %s (load error)\n%s\n', spec_name, tostring(mod_or_err)))
  else
    local mod = mod_or_err
    local test_names = {}
    for test_name, _ in pairs(mod) do
      table.insert(test_names, test_name)
    end
    table.sort(test_names)

    for _, test_name in ipairs(test_names) do
      local fn = mod[test_name]
      total = total + 1
      local ok, err = pcall(fn)
      if ok then
        passed = passed + 1
        io.write(string.format('PASS %s - %s\n', spec_name, test_name))
      else
        failed = failed + 1
        io.stderr:write(string.format('FAIL %s - %s\n%s\n', spec_name, test_name, tostring(err)))
      end
    end
  end
end

io.write(string.format('\nSummary: %d total, %d passed, %d failed\n', total, passed, failed))

if failed > 0 then
  vim.cmd('cquit 1')
end

vim.cmd('qa!')
