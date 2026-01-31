vim.loader.enable()

-- install plugins
require('config.load-plugins').setup()

-- appearance of popup menu for autocomplete
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Highlight on yank for visual feedback
local group = vim.api.nvim_create_augroup("UserConfig", {clear = true})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({timeout = 150})
  end,
  desc = "highlight yanked text"
})

-- Other plugins that we wanna load for every projects
require("config.fzf").setup()
require("config.diagnostics").setup()
require("config.projectionist").setup()
require("nvim-autopairs").setup()
require("oil").setup({
  view_options = {
    show_hidden = true
  }
})
require('mini.splitjoin').setup()

-- Colorscheme
vim.opt.termguicolors = true
pcall(vim.cmd.colorscheme, "jellybeans-nvim")
