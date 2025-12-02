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
-- Other plugins that we wanna load for every projects
------------------------------------------------------------
require('spaceless').setup()
require("config.projectionist")

-- Do not set vim.g.haskell_tools in after/ftplugin/haskell.lua, as the file is sourced after the plugin is initialized.
vim.g.haskell_tools = {
  tools = {
    log = {
      level = vim.log.levels.DEBUG,
    },
  },

  hls = {
    settings = {
      haskell = {
        formattingProvider = "ormolu",

        plugin = {
          -- Code lenses
          class = {
            codeLensOn = true,
          },
          importLens = {
            codeLensOn = true,
          },
          refineImports = {
            codeLensOn = true,
          },

          -- Wingman
          tactics = {
            codeLensOn = false,
          },

          -- Keep module names correct (Fix module name code action)
          moduleName = {
            globalOn = true,
          },

          rename = {
            config = {
              crossModule = true,
            },
            globalOn = true,
          },

          eval = {
            globalOn = false,
          },

          ["ghcide-type-lenses"] = {
            globalOn = true,
          },

          ["ghcide-completions"] = {
            globalOn = true,
            config = {
              autoExtendOn = true,
              snippetsOn = false,  -- <- disable snippet-style completions
            },
          },
        },
      },
    },
  },
}
