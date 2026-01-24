local fname = vim.api.nvim_buf_get_name(0)
local root =
  vim.fs.root(fname, { ".luarc.json", ".git" })
  or vim.fs.dirname(fname)

local lsp    = require("config.lsp")
lsp.setup()
vim.lsp.start({
  name = "lua_ls",
  cmd = { "lua-language-server" },
  root_dir = root,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})
