vim.g.haskell_tools = vim.tbl_deep_extend("force", vim.g.haskell_tools or {}, {
  hls = {
    default_settings = {
      haskell = {
        formattingProvider = "fourmolu",
        componentsLoading = "multi: whole-project",
      },
    },
    settings = function(project_root)
      local hls = require("haskell-tools").lsp
      -- Keep global defaults; let hls.json override only the keys it specifies.
      return vim.tbl_deep_extend("force", {}, hls.load_hls_settings(nil), hls.load_hls_settings(project_root))
    end,
  },
  tools = {
    codeLens = {
      autoRefresh = false,
    },
  },
})
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

