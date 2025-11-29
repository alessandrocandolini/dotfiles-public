-- ~/.config/nvim/lua/config/projectionist.lua
local M = {}

vim.g.projectionist_heuristics = {
  ["stack.yaml"] = {
    -- from src/Foo.hs -> test/FooSpec.hs
    ["src/*.hs"] = {
      alternate = "test/{}Spec.hs",
      type = "source",
    },
    -- from test/FooSpec.hs -> src/Foo.hs
    ["test/*Spec.hs"] = {
      alternate = "src/{}.hs",
      type = "test",
    },
  },

  ["*.scala"] = {
    ["src/main/scala/*.scala"] = {
      alternate = "src/test/scala/{}Spec.scala",
      type = "source",
    },
    ["src/test/scala/*Spec.scala"] = {
      alternate = "src/main/scala/{}.scala",
      type = "test",
    },
  },
}

-- Keymap: <leader>gt = "go to test" (o back a source)
vim.keymap.set("n", "<leader>gt", "<Cmd>A<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gT", "<Cmd>AV<CR>", { noremap = true, silent = true })

return M
