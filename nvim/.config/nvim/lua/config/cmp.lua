local M = {}

function M.setup()
  local cmp = require("cmp")
  local ls = require("luasnip")

  cmp.setup({
    snippet = {
      expand = function(args)
        ls.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<CR>"]      = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<Tab>"]     = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end,
      ["<S-Tab>"]   = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end,
    }),
    sources = {
      { name = "nvim_lsp" }, -- will become active once an LSP attaches
      { name = "luasnip" },  -- available immediately
    },
  })

  -- Snippet jump/expand bindings (insert + select mode)
  vim.keymap.set({ "i", "s" }, "<C-k>", function()
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
    end
  end, { silent = true })

  vim.keymap.set({ "i", "s" }, "<C-j>", function()
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end, { silent = true })
end

return M