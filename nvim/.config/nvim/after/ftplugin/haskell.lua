-- ~/.config/nvim/after/ftplugin/haskell.lua

local ht  = require("haskell-tools")
local lsp = require("config.lsp")

-- Ensure shared LSP behaviour (on_attach, <leader>ls, handlers, etc.)
lsp.setup()

-- Fidget: ONLY for Haskell (lazy init, guarded)
if not vim.g._fidget_haskell_setup then
  require("fidget").setup()
  vim.g._fidget_haskell_setup = true
end

local def_opts = { noremap = true, silent = true }

vim.g.haskell_tools = {
  tools = {
    log = {
      level = vim.log.levels.DEBUG,
    },
  },
  hls = {
    on_attach = function(client, bufnr)
      -- Haskell-specific keymaps
      local local_opts = vim.tbl_extend("keep", { buffer = bufnr }, def_opts)

      vim.keymap.set("n", "<leader>ca", vim.lsp.codelens.run,       local_opts)
      vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, local_opts)

      -- Shared LSP behaviour (all the standard maps)
      lsp.on_attach(client, bufnr)
    end,

    settings = {
      haskell = {
        formattingProvider = "ormolu",
        plugin = {
          class = { -- missing class methods
            codeLensOn = true,
          },
          importLens = { -- make import lists fully explicit
            codeLensOn = true,
          },
          refineImports = { -- refine imports
            codeLensOn = true,
          },
          tactics = { -- wingman
            codeLensOn = false,
          },
          moduleName = { -- fix module names
            globalOn = true,
          },
          rename = {
            config = {
              crossModule = false,
            },
            globalOn = true,
          },
          eval = { -- evaluate code snippets
            globalOn = false,
          },
          ["ghcide-type-lenses"] = { -- show/add missing type signatures
            globalOn = true,
          },
        },
      },
    },
  },
}

