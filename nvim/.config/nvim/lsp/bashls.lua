local lsp = require('config.lsp')
return {
  cmd = { "bash-language-server", "start" },
  filetypes = { "bash", "sh" },
  root_markers = { ".git" },
  capabilities = lsp.capabilities,
}
