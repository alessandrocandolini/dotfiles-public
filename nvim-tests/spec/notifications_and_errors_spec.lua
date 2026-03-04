local assertx = require('helpers.assert')

-- Example function with an explicit failure path.
local function validate_colorscheme_name(name)
  if type(name) ~= 'string' or name == '' then
    vim.notify('Missing colorscheme name in configuration', vim.log.levels.ERROR)
    error('colorscheme name is required')
  end
  return true
end

return {
  ['failure path emits a notification and raises an error'] = function()
    local seen = {}
    local original_notify = vim.notify

    vim.notify = function(msg, level)
      table.insert(seen, { msg = msg, level = level })
    end

    assertx.expect(function()
      validate_colorscheme_name('')
    end).to_error_matching('colorscheme name is required')

    assertx.expect(#seen).to_equal(1)
    assertx.expect(seen[1].msg).to_match('Missing colorscheme name')
    assertx.expect(seen[1].level).to_equal(vim.log.levels.ERROR)

    vim.notify = original_notify
  end,
}
