vim.cmd.packadd("haskell-tools.nvim")

require("config.haskell_snippets").setup()

local ok, ht = pcall(require, "haskell-tools")
if not ok then
  vim.notify(
    "[haskell] Failed to load haskell-tools.nvim",
    vim.log.levels.ERROR
  )
  return
end

local bufnr = vim.api.nvim_get_current_buf()
local opts = { noremap = true, silent = true, buffer = bufnr }

-- Hoogle signature lookup
vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, opts)

-- Evaluate all code snippets
vim.keymap.set('n', '<space>ea', ht.lsp.buf_eval_all, opts)

