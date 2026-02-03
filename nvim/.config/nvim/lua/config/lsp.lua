local M = {}

local lsp_format_on_save_group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })

local function is_autoformat_on_save_enabled(client)
  return client.name ~= "lua_ls" -- lua formatter is slow
end

local function lsp_setup_per_buffer(client, bufnr)
  local buf_opts = { buffer = bufnr, noremap = true, silent = true }

  -- Standard LSP keybindings (buffer-local)
  vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, buf_opts)
  vim.keymap.set('n', 'grd', vim.lsp.buf.definition, buf_opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, buf_opts)

  -- Code actions and lenses
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, buf_opts)
  vim.keymap.set('n', '<leader>cL', vim.lsp.codelens.refresh, buf_opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)
  vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, buf_opts)

  -- Formatting
  vim.keymap.set('n', '<leader>F', function()
    vim.lsp.buf.format { async = true }
  end, buf_opts)

  -- Auto format on save
  if is_autoformat_on_save_enabled(client) and client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = lsp_format_on_save_group,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr, filter = function(c) return c.id == client.id end })
      end,
    })
  end

  -- Enable inlay hints by default if supported (requires Neovim >= 0.11)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  -- Expose a key binding to hide / show inlay hints if supported
  if client.server_capabilities.inlayHintProvider then
    vim.keymap.set("n", "<leader>uh", function()
      if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
      end
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


local function lsp_setup_global()
  require("fidget").setup()

  -- set default floating preview UI (only once, as otherwise I wrap orig twice)
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

  -- helper for showing attached LSPs
  vim.keymap.set('n', '<leader>ls', list_lsp_clients, { noremap = true, silent = true, desc = "List attached LSP clients" })

  -- register per-buffer and global operations on LSP attach
  vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    group = group,
    desc = "Global LSP setup",
    callback = lsp_setup_global
  })

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
