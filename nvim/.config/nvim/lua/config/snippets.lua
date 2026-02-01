local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("UserSnippets", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = {"haskell"},
    desc = "Enable LuaSnip only for filetypes with snippets",
    callback = function(ev)
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        buffer = ev.buf,
        once = true,
        desc = "Load LuaSnip engine on first insert (buffer-local)",
        callback = function()
          pcall(vim.cmd.packadd, "LuaSnip")

          local ok, ls = pcall(require, "luasnip")
          if not ok then
            vim.notify(
              "LuaSnip is not installed or failed to load",
              vim.log.levels.WARN,
              { title = "Config" }
            )
            return
          end

          vim.api.nvim_exec_autocmds("User", { pattern = "UserLuaSnipLoaded" }) -- for async CMP / LSP integration
          require("config.haskell_snippets").setup()

          -- <Tab> expands/jumps snippets, otherwise inserts a literal tab
          vim.keymap.set({ "i", "s" }, "<Tab>", function()
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
              return ""
            end
            return "\t"
          end, { expr = true, silent = true, buffer = ev.buf })

          -- <S-Tab> jumps backwards in snippets (otherwise behaves like Shift-Tab)
          vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
            if ls.jumpable(-1) then
              ls.jump(-1)
              return ""
            end
            return "<S-Tab>"
          end, { expr = true, silent = true, buffer = ev.buf })

          -- Optional snippet navigation keys that don't steal the keypress
          vim.keymap.set({ "i", "s" }, "<C-k>", function()
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
              return ""
            end
            return "<C-k>"
          end, { expr = true, silent = true, buffer = ev.buf })

          vim.keymap.set({ "i", "s" }, "<C-j>", function()
            if ls.jumpable(-1) then
              ls.jump(-1)
              return ""
            end
            return "<C-j>"
          end, { expr = true, silent = true, buffer = ev.buf })
        end,
      })
    end,
  })
end

return M
