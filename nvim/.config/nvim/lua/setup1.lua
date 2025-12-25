------------------------------------------------------------
-- Global editor UI / options (LSP-agnostic)
------------------------------------------------------------
vim.opt_global.completeopt = { "menu", "menuone", "noselect" }

------------------------------------------------------------
-- Diagnostic
------------------------------------------------------------
local diag_opts = { noremap = true, silent = true }

vim.keymap.set("n", "[c", function()
  vim.diagnostic.goto_prev({ float = true })
end, diag_opts)

vim.keymap.set("n", "]c", function()
  vim.diagnostic.goto_next({ float = true })
end, diag_opts)

vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, diag_opts)

vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded'
  },
})

-- same as Ctrl-W d , but with autofocus on the floating box
vim.keymap.set("n", "gl", function()
  local _, winid = vim.diagnostic.open_float(nil, {
    focusable = true,
    border = "rounded",
  })
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end
end, { silent = true, desc = "Diagnostics float (enter)" })

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
