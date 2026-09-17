local fs = require('helpers.fs')
local lsp = require('helpers.lsp')

describe('LSP formatting', function()
  local root, initial_buffer, initial_buffers

  local function buffer(name)
    local path = root .. '/' .. name .. '.txt'
    fs.write_file(path, { name })
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    return vim.api.nvim_get_current_buf()
  end

  local function start(buf, name, formatting)
    local server = lsp.server({ documentFormattingProvider = formatting })
    local id = vim.lsp.start({ name = name, cmd = server.cmd, root_dir = root }, { bufnr = buf })
    lsp.wait_for(function()
      local client = vim.lsp.get_client_by_id(id)
      return client and client.initialized and client.attached_buffers[buf] ~= nil
    end)
    return server, id
  end

  local function map(buf, suffix)
    return vim.api.nvim_buf_call(buf, function()
      return vim.fn.maparg((vim.g.mapleader or '\\') .. suffix, 'n', false, true)
    end)
  end

  local function toggle(buf)
    vim.api.nvim_buf_call(buf, function() map(buf, 'uf').callback() end)
  end

  local function write(buf)
    vim.api.nvim_buf_call(buf, function() vim.cmd.write() end)
  end

  before_each(function()
    root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    initial_buffer = vim.api.nvim_get_current_buf()
    initial_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do initial_buffers[buf] = true end
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  end)

  after_each(function()
    lsp.stop_clients()
    vim.api.nvim_set_current_buf(initial_buffer)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if not initial_buffers[buf] then vim.api.nvim_buf_delete(buf, { force = true }) end
    end
    assert.equals(0, vim.fn.delete(root, 'rf'))
  end)

  it('keeps toggles buffer-local and applies formatting before writing', function()
    local a, b = buffer('A'), buffer('B')
    local server, id = start(a, 'formatter', true)
    vim.lsp.buf_attach_client(b, id)
    assert.equals(1, map(a, 'uf').buffer)
    toggle(a)
    write(a)
    write(b)
    assert.equals(1, server.count('textDocument/formatting'))
    assert.same({ 'A' }, vim.fn.readfile(root .. '/A.txt'))
    assert.same({ '// formatted', 'B' }, vim.fn.readfile(root .. '/B.txt'))
  end)

  it('preserves opt-out across detach and reattach with one save callback', function()
    local buf = buffer('A')
    local server, id = start(buf, 'formatter', true)
    toggle(buf)
    vim.lsp.buf_detach_client(buf, id)
    vim.lsp.buf_attach_client(buf, id)
    write(buf)
    assert.equals(0, server.count('textDocument/formatting'))
    toggle(buf)
    write(buf)
    assert.equals(1, server.count('textDocument/formatting'))
    assert.equals(1, #vim.api.nvim_get_autocmds({ event = 'BufWritePre', group = 'LspFormatOnSave', buffer = buf }))
  end)

  it('keeps formatting off for lua_ls until explicitly enabled', function()
    local buf = buffer('Lua')
    local server = start(buf, 'lua_ls', true)
    write(buf)
    assert.equals(0, server.count('textDocument/formatting'))
    toggle(buf)
    write(buf)
    assert.equals(1, server.count('textDocument/formatting'))
  end)

  it('manual formatting works after a nonformatting client attaches', function()
    local buf = buffer('A')
    local server = start(buf, 'formatter', true)
    start(buf, 'nonformatter', false)
    vim.api.nvim_buf_call(buf, function() map(buf, 'F').callback() end)
    lsp.wait_for(function() return server.count('textDocument/formatting') == 1 end)
    lsp.wait_for(function() return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '// formatted' end)
  end)

  it('uses the replacement client after native restart and preserves opt-out', function()
    local buf = buffer('A')
    local server, old_id = start(buf, 'formatter', true)
    toggle(buf)
    vim.api.nvim_buf_call(buf, function() vim.cmd('lsp restart') end)
    lsp.wait_for(function()
      local clients = vim.lsp.get_clients({ bufnr = buf })
      return #clients == 1 and clients[1].id ~= old_id
    end)
    write(buf)
    assert.equals(0, server.count('textDocument/formatting'))
    toggle(buf)
    write(buf)
    assert.equals(1, server.count('textDocument/formatting'))
    assert.equals(1, #vim.api.nvim_get_autocmds({ event = 'BufWritePre', group = 'LspFormatOnSave', buffer = buf }))
  end)

  it('keeps one save callback when multiple formatting clients attach', function()
    local buf = buffer('A')
    local a = start(buf, 'formatter_a', true)
    local b = start(buf, 'formatter_b', true)
    write(buf)
    assert.equals(1, a.count('textDocument/formatting'))
    assert.equals(1, b.count('textDocument/formatting'))
    assert.equals(1, #vim.api.nvim_get_autocmds({ event = 'BufWritePre', group = 'LspFormatOnSave', buffer = buf }))
  end)
end)
