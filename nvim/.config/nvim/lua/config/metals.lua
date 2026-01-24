local M = {}

function M.setup()

  vim.cmd.packadd("nvim-metals")
  local metals = require("metals")
  local lsp    = require("config.lsp")
  vim.api.nvim_set_hl(0, "@lsp.type.namespace.scala", { link = "Normal" })

  -- Ensure shared LSP behaviour is initialized (on_attach, <leader>ls, etc.)
  lsp.setup()

  local cfg = metals.bare_config()

  cfg.capabilities = lsp.capabilities

  cfg.settings = {
    showImplicitArguments = true,
    serverVersion = "latest.snapshot",
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

