-- lua/lang/scala.lua
local M = {}

function M.setup()
  -- IMPORTANT: do NOT call config.lsp.setup() from every language module.
  -- Call it ONCE from setup.lua. (Otherwise you risk multiple bootstrap handlers.)

  local boot = vim.api.nvim_create_augroup("LangScalaBoot", { clear = true })
  local attach_grp = vim.api.nvim_create_augroup("LangScalaAttach", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = boot,
    pattern = { "scala", "sbt" },
    once = true,
    callback = function(ev)
      vim.cmd.packadd("nvim-metals")

      local lsp = require("config.lsp")

      vim.api.nvim_set_hl(0, "@lsp.type.namespace.scala", { link = "Normal" })

      local metals = require("metals")
      local cfg = metals.bare_config()
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
        group = attach_grp,
        pattern = { "scala", "sbt" },
        callback = function(ev2)
          vim.api.nvim_buf_call(ev2.buf, function()
            metals.initialize_or_attach(cfg)
          end)
        end,
      })

      -- Attach ONCE for the current buffer by re-emitting FileType for that buffer.
      -- This avoids calling initialize_or_attach twice through two paths.
      vim.api.nvim_exec_autocmds("FileType", { group = attach_grp, buffer = ev.buf })
    end,
  })
end

return M
