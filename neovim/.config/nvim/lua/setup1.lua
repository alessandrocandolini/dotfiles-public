------------------------------------------------------------
-- Global Autocompletion Options & Capabilities
------------------------------------------------------------
vim.opt_global.completeopt = { "menu", "menuone", "noselect" }

-- Define a global capabilities variable for all LSP servers.
local capabilities = require('cmp_nvim_lsp').default_capabilities()

------------------------------------------------------------
-- Shared on_attach Function for LSP Clients
------------------------------------------------------------
local function on_attach(client, bufnr)
  -- Prevent duplicate key mappings if multiple LSPs attach
  if vim.b.lsp_keys_set then return end
  vim.b.lsp_keys_set = true

  local buf_opts = { buffer = bufnr, noremap = true, silent = true }

  -- Standard LSP keybindings
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, buf_opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, buf_opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, buf_opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, buf_opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, buf_opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, buf_opts)

  -- Code actions and renaming
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, buf_opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, buf_opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)

  -- Workspace folder management
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, buf_opts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, buf_opts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, buf_opts)

  -- Type definition
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, buf_opts)

  -- Quickfix list navigation
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

------------------------------------------------------------
-- Global LspAttach Autocommand (applies to ALL LSP clients)
------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    on_attach(client, ev.buf)
  end,
})

------------------------------------------------------------
-- Global Diagnostic Keymaps & Configuration
------------------------------------------------------------
local diag_opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, diag_opts)
vim.keymap.set('n', '[c', vim.diagnostic.goto_prev, diag_opts)
vim.keymap.set('n', ']c', vim.diagnostic.goto_next, diag_opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, diag_opts)

vim.diagnostic.config({
  underline = true,
  signs = true,
  virtual_text = false,
  float = {
    show_header = true,
    source = 'if_many',
    border = 'rounded',
    focusable = true,
    max_width = 80,
    max_height = 20,
  },
  update_in_insert = false,
  severity_sort = false,
})

vim.keymap.set('n', 'gl', function()
  vim.diagnostic.open_float(nil, { focus = true })
end, diag_opts)

------------------------------------------------------------
-- Autocompletion Setup Using nvim-cmp and LuaSnip
------------------------------------------------------------
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
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
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
  },
})

------------------------------------------------------------
-- Global LSP Handler Configuration (e.g. rounded borders)
------------------------------------------------------------
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

------------------------------------------------------------
-- LSP Progress Indicator (Fidget)
------------------------------------------------------------
require("fidget").setup()

------------------------------------------------------------
-- LSP Server Configuration: Metals (Scala, sbt, Java)
------------------------------------------------------------
local metals = require("metals")
local metals_config = metals.bare_config()

metals_config.capabilities = capabilities
metals_config.on_attach = on_attach  -- Use the shared on_attach function
metals_config.settings = {
  showImplicitArguments = true,
  serverVersion = "latest.snapshot",
  excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
}

local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scala", "sbt", "java" },
  group = nvim_metals_group,
  callback = function()
    metals.initialize_or_attach(metals_config)
  end,
})


------------------------------------------------------------
--  Print list of attached LSP on lopen
------------------------------------------------------------

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

  -- Location list
  vim.fn.setloclist(0, {}, "r", { title = "LSP Clients", items = items })
  vim.cmd("lopen")
end, { noremap = true, silent = true })

