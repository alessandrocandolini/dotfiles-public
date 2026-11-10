local M = {}

local function show_jump_diagnostic(diagnostic, bufnr)
  if diagnostic then
    vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false })
  end
end

function M.setup()
  vim.keymap.set('n', '<leader>dq', function()
    vim.diagnostic.setqflist({ open = true, severity = vim.diagnostic.severity.ERROR })
  end, { silent = true, desc = "Diagnostics: workspace errors (quickfix)" })

  vim.keymap.set('n', '<leader>dQ', function()
    vim.diagnostic.setqflist({ open = true })
  end, { silent = true, desc = "Diagnostics: workspace errors + warnings (quickfix)" })

  vim.diagnostic.config({
    virtual_text = false,
    jump = {
      on_jump = show_jump_diagnostic,
    },
    float = {
      border = 'rounded'
    },
  })
end
return M
