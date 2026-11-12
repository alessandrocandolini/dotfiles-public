local M = {}

function M.visible()
  local blink = package.loaded['blink.cmp']
  if blink then return blink.is_menu_visible() and 1 or 0 end
  return vim.fn.pumvisible()
end

function M.info()
  if not package.loaded['blink.cmp'] then return vim.fn.complete_info() end
  local list = require('blink.cmp.completion.list')
  return {
    selected = (list.selected_item_idx or 0) - 1,
    items = vim.tbl_map(function(item)
      return { word = item.label, user_data = { local_snippet = item.insertText } }
    end, list.items),
  }
end

return M
