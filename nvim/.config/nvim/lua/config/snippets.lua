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

          local function feed(keys)
            local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
            vim.api.nvim_feedkeys(term, "n", false)
          end

          -- TAB: if completion menu is open, go next item; else expand/jump; else insert tab
          vim.keymap.set({ "i", "s" }, "<Tab>", function()
            if vim.fn.pumvisible() == 1 then
              feed("<C-n>")
              return
            end
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
              return
            end
            feed("<Tab>")
          end, { silent = true, buffer = ev.buf })

          -- S-TAB: if completion menu is open, prev item; else jump back; else literal S-Tab
          vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
            if vim.fn.pumvisible() == 1 then
              feed("<C-p>")
              return
            end
            if ls.jumpable(-1) then
              ls.jump(-1)
              return
            end
            feed("<S-Tab>")
          end, { silent = true, buffer = ev.buf })

          -- Optional: keep these as non-expr too
          vim.keymap.set({ "i", "s" }, "<C-k>", function()
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
            else
              feed("<C-k>")
            end
          end, { silent = true, buffer = ev.buf })

          vim.keymap.set({ "i", "s" }, "<C-j>", function()
            if ls.jumpable(-1) then
              ls.jump(-1)
            else
              feed("<C-j>")
            end
          end, { silent = true, buffer = ev.buf })
        end,
      })
    end,
  })
end

return M
