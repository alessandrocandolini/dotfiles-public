vim.loader.enable()

-- Use Vim settings rather than Vi settings.
-- (Neovim is already 'nocompatible', but we keep intent explicit)
vim.opt.compatible = false

-- Enable file detection, plugin, and indentation
vim.cmd("filetype plugin indent on")

-- Switch syntax highlighting on
vim.cmd("syntax on")

-- Encoding
vim.opt.encoding = "utf-8"
vim.opt.bomb = false

-- Show invisible characters and indentation
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸ ",
  trail = "␣",
  nbsp = "¬",
}

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true

-- Statusline (only if supported)
if vim.fn.has("statusline") == 1 then
  vim.opt.statusline =
  "%<%f %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\") && &bomb)?\",B\":\"\").\"] \"}%k %-14.(%l,%c%V%) %P"
end

-- No statusline by default
vim.opt.laststatus = 0

-- Autoreload file changes outside nvim
vim.opt.autoread = true

-- Do not add empty newline at EOF
vim.opt.eol = false

-- Recursive file search in path
vim.opt.path:append("**")

-- Display end of buffer lines as blank
vim.opt.fillchars:append({ eob = " " })

-- Disable unsafe commands and ruler
vim.opt.secure = true
vim.opt.ruler = false

-- Absolute + relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = false

-- Disable mouse
vim.opt.mouse = ""

-- Disable bells
vim.opt.errorbells = false
vim.opt.belloff = "all"
vim.opt.visualbell = false

-- Responsiveness
vim.opt.updatetime = 300
vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5
vim.opt.sidescroll = 1

-- No backup files (LSP-friendly)
vim.opt.backup = false
vim.opt.writebackup = false

-- Show incomplete commands
vim.opt.showcmd = true

-- Do not change cursor shape in insert mode
vim.opt.guicursor = ""

-- Always display sign column by default (to avoid resizing the full buffer area when LSP loads)
vim.opt.signcolumn = "yes"

-- round borders for popups (useful for LSP, neovim 0.10+)
if vim.fn.exists("+winborder") == 1 then
  vim.o.winborder = "rounded"
end

-- Fix Ctrl-W v asymmetry
vim.keymap.set("n", "<C-w>v", ":vnew<CR>", { noremap = true, silent = true })

-- <leader><leader> toggles between buffers
vim.keymap.set("n", "<leader><leader>", "<c-^>", { noremap = true, silent = true })

-- Open new file adjacent to current file
vim.keymap.set("n", "<leader>o", function()
  local dir = vim.fn.expand("%:p:h") .. "/"
  vim.api.nvim_feedkeys(
    ":edit " .. vim.fn.fnameescape(dir),
    "ct",
    false
  )
end, { noremap = true })

-- toggle to wrap/unwrap long lines
vim.keymap.set("n", "<leader>wl", function()
  vim.cmd("setlocal invwrap")
end, { desc = "Toggle line wrap" })

-- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.local/share/nvim/undo")
vim.opt.undofile = true

-- Highlight on yank for visual feedback
local group = vim.api.nvim_create_augroup("UserYankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.hl_op({ timeout = 150 })
  end,
  desc = "highlight yanked text"
})

-- Enable autoread and set up checking triggers
local autoread_group = vim.api.nvim_create_augroup("UserAutoReadChecktime", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = autoread_group,
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
})

-- Load Lua setup
require("config.vimpack").setup()
require("config.diagnostics").setup()
require("config.fzf").setup()
require("config.completion").setup()
require("config.lsp").setup()
require("config.projectionist").setup()
require("config.git_blame").setup()
require("config.git_line_history").setup()

-- other plugins
require("nvim-autopairs").setup({ map_cr = false }) -- completion owns Enter
require("oil").setup({
  view_options = {
    show_hidden = true
  },
  lsp_file_methods = {
    timeout_ms = 10000,
    autosave_changes = false -- use :wa
  }
})

-- Colorscheme (must be after vimpack installation)
vim.opt.termguicolors = true
local ok, err = pcall(vim.cmd, "colorscheme jellybeans")
if not ok then
  vim.notify("Failed to load colorscheme 'jellybeans': " .. tostring(err), vim.log.levels.WARN)
end
vim.cmd([[
  highlight SignColumn guibg=NONE
]])
