local M = {}

M.languages = { "scala", "haskell", "lua", "rust", "nix" }
-- Set false to keep text objects with traditional syntax highlighting.
M.highlight = true

function M.setup()
  require("nvim-treesitter").setup({})
  require("config.haskell_textobjects").setup()
  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = false,
      selection_modes = { ["@function.outer"] = "V" },
    },
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
    pattern = M.languages,
    callback = function(ev)
      if M.highlight then
        vim.treesitter.start(ev.buf)
        -- Avoid running Vim's regex highlighter alongside Tree-sitter.
        vim.bo[ev.buf].syntax = ""
      else
        -- Some built-in ftplugins (notably Lua) start TS highlighting themselves.
        vim.treesitter.stop(ev.buf)
        vim.bo[ev.buf].syntax = vim.bo[ev.buf].filetype
      end
      for key, capture in pairs({ af = "@function.outer", ["if"] = "@function.inner" }) do
        vim.keymap.set({ "x", "o" }, key, function()
          require("nvim-treesitter-textobjects.select").select_textobject(
            capture, vim.bo[ev.buf].filetype == "haskell" and "functions" or "textobjects"
          )
        end, { buffer = ev.buf, desc = key == "af" and "Around function" or "Inside function" })
      end
    end,
  })
end

return M
