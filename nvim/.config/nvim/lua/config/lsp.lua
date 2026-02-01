-- lua/config/lsp.lua
local M = {}

-- Capabilities: cheap, and safe to call before any server starts.
function M.capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

local function on_attach_impl(client, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  vim.keymap.set("n", "grD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "grd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

  vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
  vim.keymap.set("n", "<leader>cL", vim.lsp.codelens.refresh, opts)
  vim.keymap.set({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)

  vim.keymap.set("n", "<leader>F", function()
    vim.lsp.buf.format({ async = true })
  end, opts)

  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("UserLspFormat_" .. bufnr, { clear = true }),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end

  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
    vim.keymap.set("n", "<leader>uh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, opts)
  end
end

-- Register shared LSP behavior.
-- Stateless + idempotent: we always (re)define autocmds into known augroups.
function M.setup()
  -- Per-buffer LSP maps
  local group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        on_attach_impl(client, ev.buf)
      end
    end,
  })

  -- One-time bootstrap when the FIRST LSP attaches (no flags; Neovim enforces once)
  local boot = vim.api.nvim_create_augroup("UserLspBootstrap", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = boot,
    once = true,
    callback = function()
      -- UI niceties / plugins that you only want if LSP is actually used
      pcall(function() require("fidget").setup() end)

      -- Default border for floating previews
      local orig = vim.lsp.util.open_floating_preview
      vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
        opts = opts or {}
        if opts.border == nil then opts.border = "rounded" end
        return orig(contents, syntax, opts, ...)
      end

      -- Optional cmp setup: still lazy (first LSP attach), not at startup
      local ok_cmp, cmp = pcall(require, "cmp")
      if ok_cmp then
        cmp.setup({
          snippet = {
            expand = function(args)
              pcall(function() require("luasnip").lsp_expand(args.body) end)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<Tab>"] = function(fallback)
              if cmp.visible() then cmp.select_next_item() else fallback() end
            end,
            ["<S-Tab>"] = function(fallback)
              if cmp.visible() then cmp.select_prev_item() else fallback() end
            end,
          }),
          sources = {
            { name = "nvim_lsp" },
            { name = "luasnip" },
          },
        })
      end

      -- Utility: list clients
      vim.keymap.set("n", "<leader>ls", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        local items = {}

        if #clients == 0 then
          items[1] = { filename = "", lnum = 1, col = 1, text = "No LSP clients attached" }
        else
          for _, c in ipairs(clients) do
            items[#items + 1] = { filename = "", lnum = 1, col = 1, text = "LSP client: " .. c.name }
          end
        end

        vim.fn.setloclist(0, {}, "r", { title = "LSP Clients", items = items })
        vim.cmd("lopen")
      end, { noremap = true, silent = true })
    end,
  })
end

return M
