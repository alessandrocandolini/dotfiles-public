vim.loader.enable()

-- install plugins
require('config.load-plugins').setup()

-- appearance of popup menu for autocomplete
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Custom mappings for fzf
vim.keymap.set('n', '<Leader>ff', ':Files<CR>', { silent = true })
vim.keymap.set("n", "<Leader>fg", function()
  local w = vim.fn.expand("<cWORD>") -- big word under cursor
  if w == nil or w == "" then
    vim.cmd("RG")
  else
    vim.cmd({ cmd = "RG", args = { w } })
  end
end, { silent = true })
-- to prevent accidentally triggering fzf's :Windows
vim.api.nvim_create_user_command('W', 'write', {})

vim.g.fzf_layout = { down = 20 }
vim.g.fzf_preview_window = { "right:50%:hidden", "ctrl-/" }

local extra = table.concat({
  '--info=inline',
  '--bind ctrl-q:select-all+accept'
}, " ")

vim.env.FZF_DEFAULT_OPTS = (vim.env.FZF_DEFAULT_OPTS and (vim.env.FZF_DEFAULT_OPTS .. " " .. extra)) or extra

-- Diagnostic
vim.keymap.set("n", "[c", function()
  vim.diagnostic.goto_prev({ float = true })
end, { silent = true })

vim.keymap.set("n", "]c", function()
  vim.diagnostic.goto_next({ float = true })
end, { silent = true })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { silent = true })

vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded'
  },
})

-- same as Ctrl-W d , but with autofocus on the floating box
vim.keymap.set("n", "<leader>dl", function()
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

-- Transparent background
vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight LineNr guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]])
