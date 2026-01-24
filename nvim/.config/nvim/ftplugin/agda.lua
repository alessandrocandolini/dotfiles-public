-- vim.opt_local.laststatus = 2

vim.cmd.packadd("vim-textobj-user")
vim.cmd.packadd("nvim-hs.vim")
vim.cmd.packadd("cornelis")

vim.g.cornelis_split_location = "bottom"

local opts = { buffer = true, silent = true, noremap = true }

vim.keymap.set("n", "<leader>l", "<Cmd>CornelisLoad<CR>", opts)
vim.keymap.set("n", "<leader>r", "<Cmd>CornelisRefine<CR>", opts)
vim.keymap.set("n", "<leader>d", "<Cmd>CornelisMakeCase<CR>", opts)
vim.keymap.set("n", "<leader>,", "<Cmd>CornelisTypeContext<CR>", opts)
vim.keymap.set("n", "<leader>.", "<Cmd>CornelisTypeContextInfer<CR>", opts)
vim.keymap.set("n", "<leader>s", "<Cmd>CornelisSolve<CR>", opts)
vim.keymap.set("n", "<leader>n", "<Cmd>CornelisNormalize<CR>", opts)
vim.keymap.set("n", "<leader>a", "<Cmd>CornelisAuto<CR>", opts)

vim.keymap.set("n", "gd", "<Cmd>CornelisGoToDefinition<CR>", opts)
vim.keymap.set("n", "[/", "<Cmd>CornelisPrevGoal<CR>", opts)
vim.keymap.set("n", "]/", "<Cmd>CornelisNextGoal<CR>", opts)

vim.keymap.set("n", "<C-A>", "<Cmd>CornelisInc<CR>", opts)
vim.keymap.set("n", "<C-X>", "<Cmd>CornelisDec<CR>", opts)
