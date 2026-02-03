local lsp = require('config.lsp')
return {
  cmd = { "nil"},
  settings = {
    formatting = {
      command = { "nixfmt" }
    }
  },
  filetypes = { "nix" },
  root_markers = { "flake.nix", "shell.nix", ".git" },
  capabilities = lsp.capabilities,
}
