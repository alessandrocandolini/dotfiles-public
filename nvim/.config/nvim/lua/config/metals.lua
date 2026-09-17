local M = {}
local first_save_group = vim.api.nvim_create_augroup("MetalsFirstSave", { clear = true })

function M.setup()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_clear_autocmds({ group = first_save_group, buffer = bufnr })

  if (vim.bo.filetype ~= "scala" and vim.bo.filetype ~= "sbt")
      or vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(bufnr) == "" then
    return
  end

  -- Include clients that are still initializing, so repeated setup cannot
  -- duplicate attachment work while a workspace is starting.
  if #vim.lsp.get_clients({ bufnr = bufnr, name = "metals", _uninitialized = true }) > 0 then
    return
  end

  -- nvim-metals rejects files that do not exist yet. Retry after the first
  -- write, in the saved buffer's context (also works for :wall).
  if not vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr)) then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = first_save_group,
      buffer = bufnr,
      once = true,
      callback = function(ev)
        vim.api.nvim_buf_call(ev.buf, M.setup)
      end,
    })
    return
  end

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

  -- Scala's ftplugin (also inherited by sbt) owns per-buffer setup.
  -- For restart, use native :lsp restart, which restores attached buffers.
  metals.initialize_or_attach(cfg)
end

return M
