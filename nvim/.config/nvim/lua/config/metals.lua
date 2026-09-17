local M = {}

function M.setup()

  vim.cmd.packadd("nvim-metals")

  vim.api.nvim_set_hl(0, "@lsp.type.namespace.scala", { link = "Normal" })

  local metals = require("metals")
  local cfg = metals.bare_config()

  local lsp    = require("config.lsp")
  cfg.capabilities = lsp.capabilities

  cfg.settings = {
    showImplicitArguments = true,
    serverVersion = "1.6.8",
    excludedPackages = {
      "akka.actor.typed.javadsl",
      "com.github.swagger.akka.javadsl",
    },
  }

  -- The Scala ftplugin (also inherited by sbt) calls setup for each buffer.
  if vim.bo.filetype == "scala" or vim.bo.filetype == "sbt" then
    metals.initialize_or_attach(cfg)
  end
end

return M
