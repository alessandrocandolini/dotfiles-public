local M = {}

function M.visible()
  return require('cmp').core.view:visible() and 1 or 0
end

function M.info()
  local view = require('cmp').core.view
  local selected = view:get_selected_entry()
  local info = { selected = -1, items = {} }
  for index, entry in ipairs(view:get_entries()) do
    info.items[index] = { word = entry:get_completion_item().label }
    if entry == selected then info.selected = index - 1 end
  end
  return info
end

return M
