vim.loader.enable()

require('config.vimpack').setup()
require("config.appearance").setup() -- must be after installing the plugins
require("config.diagnostics").setup()
require("config.fzf").setup()
require("config.cmp").setup()
require("config.lsp").setup()
require("config.projectionist").setup()

-- other plugins
require("nvim-autopairs").setup()
require("oil").setup({
  view_options = {
    show_hidden = true
  }
})
