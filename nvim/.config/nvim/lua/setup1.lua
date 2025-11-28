------------------------------------------------------------
-- Global editor UI / options (LSP-agnostic)
------------------------------------------------------------
vim.opt_global.completeopt = { "menu", "menuone", "noselect" }

------------------------------------------------------------
-- Global Diagnostic Keymaps & Configuration
-- (These work fine even when *no* LSP is active)
------------------------------------------------------------
local diag_opts = { noremap = true, silent = true }

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, diag_opts)
vim.keymap.set('n', '[c', vim.diagnostic.goto_prev,        diag_opts)
vim.keymap.set('n', ']c', vim.diagnostic.goto_next,        diag_opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, diag_opts)

vim.diagnostic.config({
  underline = true,
  signs = true,
  virtual_text = false,
  float = {
    show_header = true,
    source = 'if_many',
    border = 'rounded',
    focusable = true,
    max_width = 80,
    max_height = 20,
  },
  update_in_insert = false,
  severity_sort = false,
})

vim.keymap.set('n', 'gl', function()
  vim.diagnostic.open_float(nil, { focus = true })
end, diag_opts)

------------------------------------------------------------
-- Generic non-LSP plugins
------------------------------------------------------------
require('spaceless').setup()

