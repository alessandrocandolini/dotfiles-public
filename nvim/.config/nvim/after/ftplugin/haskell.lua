-- ~/.config/nvim/after/ftplugin/haskell.lua

local ht  = require("haskell-tools")
local lsp = require("config.lsp")

lsp.setup()

require("config.haskell_snippets").setup()

local bufnr = vim.api.nvim_get_current_buf()
local opts = { noremap = true, silent = true, buffer = bufnr }

-- Run codelens in this buffer
vim.keymap.set("n", "<leader>ca", vim.lsp.codelens.run, opts)

-- Hoogle signature lookup
vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, opts)

-- Evaluate all code snippets
vim.keymap.set('n', '<space>ea', ht.lsp.buf_eval_all, opts)

