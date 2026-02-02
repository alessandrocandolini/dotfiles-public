local M = {}

function M.setup()
  local ok_cmp, cmp = pcall(require, "cmp")
  if not ok_cmp then
    vim.notify("cmp is not installed or failed to load", vim.log.levels.WARN, { title = "Config" })
    return
  end
  local ok_ls, ls = pcall(require, "luasnip")
  local sources = {}
  local snippet = nil

  if ok_ls then
    snippet = {
      expand = function(args)
        ls.lsp_expand(args.body)
      end,
    }
    table.insert(sources, { name = "luasnip" })
  end

  local ok_cmp_lsp, _ = pcall(require, "cmp_nvim_lsp")
  if ok_cmp_lsp then
    -- will become active once an LSP attaches
    table.insert(sources, { name = "nvim_lsp" })
  end

  cmp.setup({
    snippet = snippet,
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
    sources = sources
  })

  if not ok_ls then
    return
  end
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
