-- ~/.config/nvim/lua/config/cmp.lua
local M = {}

local function has_source(sources, name)
  for _, s in ipairs(sources or {}) do
    if s.name == name then
      return true
    end
  end
  return false
end

local function add_lsp_source_if_needed(cmp)
  local cfg = cmp.get_config()
  local sources = cfg.sources or {}

  if has_source(sources, "nvim_lsp") then
    return
  end

  cmp.setup({
    sources = cmp.config.sources(
      { { name = "nvim_lsp" } },
      sources
    ),
  })
end

function M.setup()
  vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    desc = "Enable nvim-cmp (works even without LSP)",
    callback = function()
      local cmp = require("cmp")

      local sources = {
        { name = "buffer" },
        { name = "path" },
      }

      if pcall(require, "luasnip") then
        pcall(vim.cmd.packadd, "cmp_luasnip")
        table.insert(sources, 1, { name = "luasnip" })
      end

      if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
        table.insert(sources, 1, { name = "nvim_lsp" })
      end

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        }),
        sources = sources,
      })

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "UserLuaSnipLoaded",
        desc = "Add LuaSnip source to cmp after LuaSnip loads",
        callback = function()
          pcall(vim.cmd.packadd, "cmp_luasnip")
          local cfg = cmp.get_config()
          local cur = cfg.sources or {}
          if not has_source(cur, "luasnip") then
            cmp.setup({
              sources = cmp.config.sources({ { name = "luasnip" } }, cur),
            })
          end
        end,
      })

      -- If LSP attaches later, upgrade cmp sources (idempotent).
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "Add nvim_lsp source to cmp after LSP attaches",
        callback = function()
          add_lsp_source_if_needed(cmp)
        end,
      })
    end,
  })
end

return M
