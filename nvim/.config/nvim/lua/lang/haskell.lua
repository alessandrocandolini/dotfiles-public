local M = {}

function M.setup()
  -- Shared LSP behavior (LspAttach keymaps, diagnostic UI, etc.)
  -- This should be stateless/idempotent in your refactor.
  require("config.lsp").setup()

  local boot = vim.api.nvim_create_augroup("LangHaskellBoot", { clear = true })
  local maps = vim.api.nvim_create_augroup("LangHaskellMaps", { clear = true })

  -- Bootstrap: once per session, only when Haskell becomes relevant
  vim.api.nvim_create_autocmd("FileType", {
    group = boot,
    pattern = { "haskell", "lhaskell", "cabal" },
    once = true,
    callback = function()
      vim.cmd.packadd("haskell-tools.nvim")

      -- Your snippets setup (you had this before)
      pcall(function()
        require("config.haskell_snippets").setup()
      end)

      -- Per-buffer mappings (every Haskell buffer)
      vim.api.nvim_create_autocmd("FileType", {
        group = maps,
        pattern = { "haskell", "lhaskell", "cabal" },
        callback = function(ev)
          local ok, ht = pcall(require, "haskell-tools")
          if not ok then
            vim.notify("[haskell] Failed to load haskell-tools.nvim", vim.log.levels.ERROR)
            return
          end

          local bufnr = ev.buf
          local opts = { noremap = true, silent = true, buffer = bufnr }

          -- Your mappings
          vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, opts)
          vim.keymap.set("n", "<space>ea", ht.lsp.buf_eval_all, opts)

          -- (Optional but commonly useful with HLS)
          -- vim.keymap.set("n", "<space>cl", vim.lsp.codelens.run, opts)
        end,
      })

      -- Also apply mappings immediately to the buffer that triggered bootstrap
      local bufnr = vim.api.nvim_get_current_buf()
      local ft = vim.bo[bufnr].filetype
      if ft == "haskell" or ft == "lhaskell" or ft == "cabal" then
        vim.api.nvim_exec_autocmds("FileType", { group = maps, buffer = bufnr })
      end
    end,
  })
end

return M
