local M = {}

function M.setup()

  vim.cmd.packadd("nvim-metals")

  vim.api.nvim_set_hl(0, "@lsp.type.namespace.scala", { link = "Normal" })

  local metals = require("metals")
  local cfg = metals.bare_config()

  local lsp    = require("config.lsp")
  cfg.capabilities = lsp.capabilities()

  cfg.settings = {
    showImplicitArguments = true,
    serverVersion = "1.6.5",
    excludedPackages = {
      "akka.actor.typed.javadsl",
      "com.github.swagger.akka.javadsl",
    },
  }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt" },
    callback = function()
      metals.initialize_or_attach(cfg)
    end,
  })

  -- if setup() runs after a scala buffer is already open
  if vim.bo.filetype == "scala" or vim.bo.filetype == "sbt" then
    metals.initialize_or_attach(cfg)
  end
end

return M

