local M = {}

local lsp_format_on_save_group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })

local function is_autoformat_on_save_enabled(client)
  return client.name ~= "lua_ls"   -- lua formatter is slow
end

local function lsp_setup_per_buffer(client, bufnr)
  local buf_opts = { buffer = bufnr, noremap = true, silent = true }

  -- Standard LSP keybindings (buffer-local)
  vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, buf_opts)
  vim.keymap.set('n', 'grd', vim.lsp.buf.definition, buf_opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, buf_opts)

  -- Code actions and lenses
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, buf_opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)
  vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, buf_opts)

  -- Formatting
  vim.keymap.set('n', '<leader>F', function()
    vim.lsp.buf.format({ async = true })
  end, buf_opts)

  -- Auto format on save
  if client:supports_method('textDocument/formatting', bufnr) then
    if vim.b[bufnr].lsp_format_on_save == nil then
      vim.b[bufnr].lsp_format_on_save = is_autoformat_on_save_enabled(client)
    end

    vim.keymap.set("n", "<leader>uf", function()
      vim.b[bufnr].lsp_format_on_save = not vim.b[bufnr].lsp_format_on_save
      print("Format on save: " .. tostring(vim.b[bufnr].lsp_format_on_save))
    end, buf_opts)

    -- One callback per buffer, with no captured client ID or reset on restart.
    vim.api.nvim_clear_autocmds({ group = lsp_format_on_save_group, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = lsp_format_on_save_group,
      buffer = bufnr,
      callback = function()
        if vim.b[bufnr].lsp_format_on_save then
          vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
        end
      end
    })
  end

  -- Expose a key binding to hide / show inlay hints if supported
  if client.server_capabilities.inlayHintProvider then
    vim.keymap.set("n", "<leader>uh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, { buffer = bufnr, silent = true })
  end
end

local function list_lsp_clients()
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
end

local function client_capabilities()
  local base = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_lsp.default_capabilities(base)
  end
  return base
end

M.capabilities = client_capabilities()

function M.setup()
  require("fidget").setup()

  -- Set the default once; buffer toggles survive later attachments and restarts.
  vim.lsp.inlay_hint.enable(true)
  vim.lsp.semantic_tokens.enable(false)
  vim.lsp.codelens.enable(true)

  local group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })
  -- enable servers
  if vim.fn.executable('lua-language-server') == 1 then
    vim.lsp.enable('lua_ls')
  end
  if vim.fn.executable('bash-language-server') == 1 then
    vim.lsp.enable('bashls')
  end
  if vim.fn.executable('nil') == 1 then
    vim.lsp.enable('nil_ls')
  end
  if vim.fn.executable('rust-analyzer') == 1 then
    vim.lsp.enable('rust-analyzer')
  end
  -- helper for showing attached LSPs
  vim.keymap.set('n', '<leader>ls', list_lsp_clients,
    { noremap = true, silent = true, desc = "List attached LSP clients" })

  -- register per-buffer operations on LSP attach
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Per-buffer LSP setup",
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        lsp_setup_per_buffer(client, ev.buf)
      end
    end,
  })
end

return M
