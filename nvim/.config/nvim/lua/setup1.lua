vim.loader.enable()

-- install plugins
local pack = require('config.pack_utils')

local packchanged_group = vim.api.nvim_create_augroup("PackChangedPostInstall", { clear = true })
vim.api.nvim_create_autocmd("PackChanged", {
  group = packchanged_group,
  callback = pack.post_processing_hook(function(h)
    h:on("cornelis", { "stack", "build" })
  end),
})

-- Global plugins
local gh   = pack.gh
vim.pack.add({
  gh("rktjmp/lush.nvim"), -- required by jellybeans-nvim
  gh("metalelf0/jellybeans-nvim"),

  gh("ibhagwan/fzf-lua"),
  gh("nvim-lua/plenary.nvim"),
  gh("axelf4/vim-strip-trailing-whitespace"),
  gh("windwp/nvim-autopairs"),
  gh("tpope/vim-projectionist"),
  gh("j-hui/fidget.nvim"), -- LSP loader indicator
  gh("stevearc/oil.nvim"),
  gh("nvim-mini/mini.splitjoin"),

  -- completion/snippets
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("L3MON4D3/LuaSnip"),
  gh("saadparwaiz1/cmp_luasnip"),

}, { load = true })

-- Optional plugins (they are loaded on specific buffers in ftplugin)
vim.pack.add({
  { src = gh("scalameta/nvim-metals"), name = "nvim-metals" },
  { src = gh("Mrcjkb/haskell-tools.nvim"), name = "haskell-tools.nvim" },
  { src = gh("kana/vim-textobj-user"), name = "vim-textobj-user" }, -- required by cornelis
  { src = gh("neovimhaskell/nvim-hs.vim"), name = "nvim-hs.vim" }, -- required by cornelis
  { src = gh("agda/cornelis"), name = "cornelis" },
}, { load = false })

-- appearance of popup menu for autocomplete
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Diagnostic
vim.keymap.set("n", "[c", function()
  vim.diagnostic.goto_prev({ float = true })
end, { silent = true })

vim.keymap.set("n", "]c", function()
  vim.diagnostic.goto_next({ float = true })
end, { silent = true })

vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { silent = true, desc = "Diagnostics: buffer (loclist)" })

vim.keymap.set('n', '<leader>dq', function()
  vim.diagnostic.setqflist({ open = true })
end, { silent = true, desc = "Diagnostics: workspace (quickfix)" })

vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded'
  },
})

-- same as Ctrl-W d , but with autofocus on the floating box
vim.keymap.set("n", "<leader>df", function()
  local _, winid = vim.diagnostic.open_float(nil, {
    focusable = true,
    border = "rounded",
  })
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end
end, { silent = true, desc = "Diagnostics float (enter)" })

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
require("config.projectionist")
require("nvim-autopairs").setup {}
require("oil").setup({
  view_options = {
    show_hidden = true
  }
})
require('mini.splitjoin').setup()

-- Colorscheme
vim.opt.termguicolors = true
pcall(vim.cmd.colorscheme, "jellybeans-nvim")
