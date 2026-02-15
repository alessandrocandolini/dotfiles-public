local lsp = require("config.lsp")
return {
  capabilities = lsp.capabilities,
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        features = "all",
      },

      checkOnSave = {
        enable = true,
      },

      check = {
        command = "clippy",
      },

      imports = {
        group = {
          enable = false,
        },
      },

      completion = {
        postfix = {
          enable = false,
        },
      },
    },
  },
}
