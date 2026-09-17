local lsp = require('helpers.lsp')

describe('LSP inlay hints', function()
  local function start(server, buf, name)
    local id = vim.lsp.start({ name = name, cmd = server.cmd }, { bufnr = buf })
    lsp.wait_for(function()
      local client = vim.lsp.get_client_by_id(id)
      return client and client.initialized and client.attached_buffers[buf] ~= nil
    end)
    return id
  end

  after_each(lsp.stop_clients)

  it('preserves the buffer toggle across restart and another attachment', function()
    local server = lsp.server({ inlayHintProvider = true })
    local a = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(a)
    local old_id = start(server, a, 'hints-one')
    assert.is_true(vim.lsp.inlay_hint.is_enabled({ bufnr = a }))
    local toggle = vim.fn.maparg((vim.g.mapleader or '\\') .. 'uh', 'n', false, true).callback
    toggle()
    vim.cmd('lsp restart')
    lsp.wait_for(function()
      local clients = vim.lsp.get_clients({ bufnr = a })
      return #clients == 1 and clients[1].id ~= old_id
    end)
    assert.is_false(vim.lsp.inlay_hint.is_enabled({ bufnr = a }))
    start(server, a, 'hints-two')
    assert.is_false(vim.lsp.inlay_hint.is_enabled({ bufnr = a }))
    local b = vim.api.nvim_create_buf(true, false)
    start(server, b, 'hints-one')
    assert.is_true(vim.lsp.inlay_hint.is_enabled({ bufnr = b }))
  end)
end)
