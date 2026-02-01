-- lua/lang/lua.lua
local M = {}

function M.setup()
  if vim.fn.executable("lua-language-server") ~= 1 then
    vim.schedule(function()
      vim.notify("[lua] lua-language-server not found in PATH", vim.log.levels.WARN)
    end)
    return
  end

  local lsp = require("config.lsp")

  vim.lsp.config["lua_ls"] = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_dir = function(fname)
      return vim.fs.root(fname, { ".luarc.json", ".luarc.jsonc", ".git" })
        or vim.fs.dirname(fname)
    end,
    capabilities = lsp.capabilities(),
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  }

  vim.lsp.enable("lua_ls")

  -- 🔑 Deterministic attach: re-fire FileType for any already-open lua buffers
  local grp = vim.api.nvim_create_augroup("LangLuaAttachOnce", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = grp,
    once = true,
    callback = function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "lua" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
        end
      end
    end,
  })
end

return M
