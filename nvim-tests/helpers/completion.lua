local M = {}

function M.visible()
  return vim.fn.pumvisible()
end

function M.info()
  return vim.fn.complete_info()
end

return M
