-- ~/.config/nvim/lua/config/metals.lua

local M = {}

local initialized = false

function M.setup()
  if initialized then
    return
  end
  initialized = true

  local metals = require("metals")
  local lsp    = require("config.lsp")

  -- Ensure shared LSP behaviour is initialized (on_attach, <leader>ls, etc.)
  lsp.setup()

  local cfg = metals.bare_config()

  cfg.capabilities = lsp.capabilities
  cfg.on_attach    = lsp.on_attach

  cfg.settings = {
    showImplicitArguments = true,
    serverVersion = "latest.snapshot",
    excludedPackages = {
      "akka.actor.typed.javadsl",
      "com.github.swagger.akka.javadsl",
    },
  }

  metals.initialize_or_attach(cfg)
end

return M

