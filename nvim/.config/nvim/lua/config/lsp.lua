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
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration,        buf_opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition,         buf_opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation,     buf_opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references,         buf_opts)
  vim.keymap.set('n', 'K',  vim.lsp.buf.hover,              buf_opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help,  buf_opts)

  -- Code actions and renaming
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run,          buf_opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,            buf_opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)

  -- Workspace folder management
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder,    buf_opts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, buf_opts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, buf_opts)

  -- Type definition
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, buf_opts)

  -- Quickfix list navigation (for LSP-driven lists)
  vim.keymap.set('n', ']q', ":cnext<CR>", buf_opts)
  vim.keymap.set('n', '[q', ":cprev<CR>", buf_opts)
  vim.keymap.set('n', '<leader>qq', ":copen<CR>", buf_opts)

  -- Formatting
  vim.keymap.set('n', '<leader>F', function()
    print("formatting...")
    vim.lsp.buf.format { async = true }
  end, buf_opts)

  -- Enable inlay hints if supported (Neovim 0.10+)
  if vim.lsp.buf.inlay_hint then
    vim.lsp.buf.inlay_hint(bufnr, true)
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

  -- LSP handler UI (hover/signature borders)
  if not vim.g.lsp_handlers_configured then
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      vim.lsp.handlers.hover,
      { border = "rounded" }
    )
    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
      vim.lsp.handlers.signature_help,
      { border = "rounded" }
    )
    vim.g.lsp_handlers_configured = true
  end

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
