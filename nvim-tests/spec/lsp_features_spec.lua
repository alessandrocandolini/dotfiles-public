local lsp = require('helpers.lsp')

describe('LSP feature defaults', function()
  local initial_buffer, buffers

  local function buffer()
    local buf = vim.api.nvim_create_buf(true, false)
    buffers[#buffers + 1] = buf
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'example' })
    return buf
  end

  local function start(server, buf, name)
    local id = vim.lsp.start({ name = name, cmd = server.cmd }, { bufnr = buf })
    lsp.wait_for(function()
      local client = vim.lsp.get_client_by_id(id)
      return client and client.initialized and client.attached_buffers[buf] ~= nil
    end)
    return id
  end

  before_each(function()
    initial_buffer, buffers = vim.api.nvim_get_current_buf(), {}
  end)

  after_each(function()
    lsp.stop_clients()
    vim.api.nvim_set_current_buf(initial_buffer)
    for _, buf in ipairs(buffers) do vim.api.nvim_buf_delete(buf, { force = true }) end
  end)

  it('keeps semantic tokens off without removing capabilities across buffers and restart', function()
    local server = lsp.server({
      semanticTokensProvider = {
        full = true,
        legend = { tokenTypes = { 'variable' }, tokenModifiers = {} },
      },
      codeLensProvider = {},
    })
    local a = buffer()
    local id = start(server, a, 'feature-server')
    local b = buffer()
    vim.lsp.buf_attach_client(b, id)
    lsp.wait_for(function() return server.count('textDocument/codeLens') >= 2 end)

    local function check(client_id)
      local client = vim.lsp.get_client_by_id(client_id)
      assert.is_not_nil(client.server_capabilities.semanticTokensProvider)
      for _, buf in ipairs({ a, b }) do
        assert.is_not_nil(client.attached_buffers[buf])
        assert.is_false(vim.lsp.semantic_tokens.is_enabled({ bufnr = buf }))
      end
      assert.equals(0, server.count('textDocument/semanticTokens/full'))
    end
    check(id)

    local requests = server.count('textDocument/codeLens')
    vim.cmd('lsp restart')
    lsp.wait_for(function() return server.count('textDocument/codeLens') >= requests + 2 end)
    local restarted = vim.lsp.get_clients({ bufnr = b })[1]
    assert.is_not.equals(id, restarted.id)
    check(restarted.id)
  end)

  it('requests code lenses only from supporting clients sharing a buffer', function()
    local buf = buffer()
    local supported = lsp.server({ codeLensProvider = {} })
    local unsupported = lsp.server()
    start(unsupported, buf, 'without-lenses')
    start(supported, buf, 'with-lenses')
    lsp.wait_for(function() return supported.count('textDocument/codeLens') > 0 end)
    assert.equals(0, unsupported.count('textDocument/codeLens'))
  end)
end)
