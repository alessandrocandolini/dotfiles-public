local M = {}

function M.setup()

  -- Colorscheme
  vim.opt.termguicolors = true
  pcall(vim.cmd.colorscheme, "jellybeans-nvim")

  -- Highlight on yank for visual feedback
  local group = vim.api.nvim_create_augroup("UserConfig", {clear = true})
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
      vim.highlight.on_yank({timeout = 150})
    end,
    desc = "highlight yanked text"
  })

  -- appearance of popup menu for autocomplete
  vim.opt.completeopt = { "menu", "menuone", "noselect" }

end

return M
