local M = {}

local function show_jump_diagnostic(diagnostic, bufnr)
  if diagnostic then
    vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false })
  end
end

function M.setup()
  vim.keymap.set("n", "[c", function()
    vim.diagnostic.jump({ count = -1, on_jump = show_jump_diagnostic })
  end, { silent = true, desc = "Diagnostics: previous (float)" })

  vim.keymap.set("n", "]c", function()
    vim.diagnostic.jump({ count = 1, on_jump = show_jump_diagnostic })
  end, { silent = true, desc = "Diagnostics: next (float)" })

  vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { silent = true, desc = "Diagnostics: buffer (loclist)" })

  vim.keymap.set('n', '<leader>dq', function()
    vim.diagnostic.setqflist({ open = true })
  end, { silent = true, desc = "Diagnostics: workspace (quickfix)" })

  vim.diagnostic.config({
    virtual_text = false,
    float = {
      border = 'rounded'
    },
  })

  -- same as Ctrl-W d , but with autofocus on the floating box
  vim.keymap.set("n", "<leader>df", function()
    local _, winid = vim.diagnostic.open_float(nil, {
      focusable = true,
      border = "rounded",
    })
    if winid and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
    end
  end, { silent = true, desc = "Diagnostics float (focused)" })
end
return M
