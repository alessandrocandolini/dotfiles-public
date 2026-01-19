-- appearance of popup menu for autocomplete
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Diagnostic
local diag_opts = { noremap = true, silent = true }

vim.keymap.set("n", "[c", function()
  vim.diagnostic.goto_prev({ float = true })
end, diag_opts)

vim.keymap.set("n", "]c", function()
  vim.diagnostic.goto_next({ float = true })
end, diag_opts)

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, diag_opts)

vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded'
  },
})

-- same as Ctrl-W d , but with autofocus on the floating box
vim.keymap.set("n", "<leader>dl", function()
  local _, winid = vim.diagnostic.open_float(nil, {
    focusable = true,
    border = "rounded",
  })
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end
end, { silent = true, desc = "Diagnostics float (enter)" })

-- Other plugins that we wanna load for every projects
require("config.projectionist")
require("nvim-autopairs").setup {}
