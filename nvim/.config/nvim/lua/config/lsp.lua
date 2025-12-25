-- ~/.config/nvim/lua/config/lsp.lua
local M = {}

------------------------------------------------------------
-- Shared on_attach Function for LSP Clients
-- (ALL buffer-local LSP keymaps live here)
------------------------------------------------------------
local function on_attach_impl(client, bufnr)
  -- Prevent duplicate key mappings if multiple LSPs attach
  if vim.b.lsp_keys_set then return end
  vim.b.lsp_keys_set = true


  local buf_opts = { buffer = bufnr, noremap = true, silent = true }

  -- Standard LSP keybindings (buffer-local)
  vim.keymap.set('n', 'grD', vim.lsp.buf.declaration,        buf_opts)
  vim.keymap.set('n', 'grd', vim.lsp.buf.definition,         buf_opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help,  buf_opts)

  -- Code actions and lenses
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, buf_opts)
  vim.keymap.set('n', '<leader>cL', vim.lsp.codelens.refresh, buf_opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)
  vim.keymap.set('n', '<leader>ss', vim.lsp.buf.workspace_symbol, buf_opts)

  -- Formatting
  vim.keymap.set('n', '<leader>F', function()
    vim.lsp.buf.format { async = true }
  end, buf_opts)

  -- Enable inlay hints if supported (requires Neovim > 0.11)
  if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
    vim.keymap.set("n", "<leader>uh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, { buffer = bufnr, silent = true })
  end

end

function M.on_attach(client, bufnr)
  on_attach_impl(client, bufnr)
end

------------------------------------------------------------
-- Lazy setup: called once from language ftplugins
------------------------------------------------------------
local initialized = false

function M.setup()
  if initialized then return end
  initialized = true

  require("fidget").setup()

  -- Force a default border for all LSP floating previews (hover, signature, etc.)
  if not vim.g._user_lsp_float_border then
    vim.g._user_lsp_float_border = true

    local orig = vim.lsp.util.open_floating_preview
    vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
      opts = opts or {}
      if opts.border == nil then
        opts.border = "rounded"
      end
      return orig(contents, syntax, opts, ...)
    end
  end


  --------------------------------------------------------
  -- Capabilities (nvim-cmp + LSP)
  --------------------------------------------------------
  local cmp_lsp = require('cmp_nvim_lsp')
  M.capabilities = cmp_lsp.default_capabilities()

  --------------------------------------------------------
  -- nvim-cmp + LuaSnip
  --------------------------------------------------------
  local cmp = require("cmp")

  cmp.setup({
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<CR>']      = cmp.mapping.confirm({ select = true }),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<Tab>']     = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end,
      ['<S-Tab>']   = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end,
    }),
    sources = {
      { name = "nvim_lsp" },
      { name = "luasnip" },
    },
  })


  local ls = require("luasnip")

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


  --------------------------------------------------------
  -- LspAttach autocommand (usa on_attach_impl)
  --------------------------------------------------------
  local group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        M.on_attach(client, ev.buf)
      end
    end,
  })


  -- Print list of attached LSP clients (LSP-specific utility)
  vim.keymap.set('n', '<leader>ls', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    local items = {}
    if #clients == 0 then
      table.insert(items, {
        filename = "",
        lnum = 1,
        col = 1,
        text = "No LSP clients attached",
      })
    else
      for _, client in ipairs(clients) do
        table.insert(items, {
          filename = "",
          lnum = 1,
          col = 1,
          text = "LSP client: " .. client.name,
        })
      end
    end

    vim.fn.setloclist(0, {}, "r", { title = "LSP Clients", items = items })
    vim.cmd("lopen")
  end, { noremap = true, silent = true })
end

return M
