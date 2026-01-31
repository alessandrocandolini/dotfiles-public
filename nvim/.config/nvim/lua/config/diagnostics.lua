local M = {}

function M.setup()
  vim.keymap.set("n", "[c", function()
    vim.diagnostic.goto_prev({ float = true })
  end, { silent = true })

  vim.keymap.set("n", "]c", function()
    vim.diagnostic.goto_next({ float = true })
  end, { silent = true })

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
  end, { silent = true, desc = "Diagnostics float (enter)" })
end
return M
