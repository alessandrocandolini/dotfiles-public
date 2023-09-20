-- ~/.config/nvim/after/ftplugin/haskell.lua
local ht = require('haskell-tools')
local bufnr = vim.api.nvim_get_current_buf()
local def_opts = { noremap = true, silent = true, buffer = bufnr, }

vim.g.haskell_tools = {
  tools = { -- haskell-tools options
    log = {
      level = vim.log.levels.DEBUG,
    },
  },
  hls = {
  on_attach = function(client, bufnr)
      local local_opts = vim.tbl_extend('keep', opts, { buffer = bufnr, })
      vim.keymap.set('n', '<leader>ca', vim.lsp.codelens.run, local_opts)
      vim.keymap.set('n', '<leader>hs', ht.hoogle.hoogle_signature, local_opts)
      default_on_attach(client, bufnr)
    end,
  settings = {
    haskell = {
      formattingProvider = 'ormolu',
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
         config= {
                    crossModule= false
                },
          globalOn = true,
        },
        eval = { -- evaluate code snippets
          globalOn = false,
        },
        ['ghcide-type-lenses'] = { -- show/add missing type signatures
          globalOn = true,
        },
      },
    },
  },
},
}
