vim.loader.enable()

require('config.vimpack').setup()
require("config.appearance").setup() -- must be after installing the plugins
require("config.diagnostics").setup()
require("config.fzf").setup()
require("config.projectionist").setup()

-- languages
require("config.lsp").setup()
require("lang.scala").setup()
require("lang.haskell").setup()
require("lang.lua").setup()

-- other plugins
require("nvim-autopairs").setup()
require("oil").setup({
  view_options = {
    show_hidden = true
  }
})
require('mini.splitjoin').setup()
