return {
  cmd = { "nil"},
  settings = {
    ["nil"] = {
      formatting = {
        command = { "nixfmt" }
      }
    },
  },
  filetypes = { "nix" },
  root_markers = { "flake.nix", "shell.nix", ".git" },
}
