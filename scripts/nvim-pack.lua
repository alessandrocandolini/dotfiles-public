-- Headless entrypoint; deliberately independent of a working editor configuration.
local repo = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
local config = arg[2] or (repo .. "/nvim/.config/nvim")
vim.opt.runtimepath:prepend(config)
local ok, err = pcall(function()
  require("config.vimpack").manage(arg[1], config .. "/nvim-pack-lock.json")
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
