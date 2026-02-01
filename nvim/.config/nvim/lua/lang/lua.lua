-- lua/lang/lua.lua
local M = {}

function M.setup()
  local lsp = require("config.lsp")
  lsp.setup()

  if vim.fn.executable("lua-language-server") ~= 1 then
    vim.schedule(function()
      vim.notify("[lua] lua-language-server not found in PATH", vim.log.levels.WARN)
    end)
    return
  end

  vim.lsp.config["lua_ls"] = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },

    root_markers = {
      ".emmyrc.json",
      ".luarc.json",
      ".luarc.jsonc",
      ".luacheckrc",
      ".stylua.toml",
      "stylua.toml",
      "selene.toml",
      "selene.yml",
      ".git",
    },

    capabilities = lsp.capabilities(),

    on_init = function(client)
      -- Keep this exactly like the working snippet (it’s good)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if
            path ~= vim.fn.stdpath("config")
            and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
        then
          return
        end
      end

      client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
        runtime = {
          version = "LuaJIT",
          path = {
            "lua/?.lua",
            "lua/?/init.lua",
          },
        },
        diagnostics = { globals = { "vim" } },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        telemetry = { enable = false },
      })
    end,

    settings = {
      Lua = {
        codeLens = { enable = true },
        hint = { enable = true, semicolon = "Disable" },
      },
    },
  }

  vim.lsp.enable("lua_ls")
end

return M
