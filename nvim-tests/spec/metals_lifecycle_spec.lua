local fs = require('helpers.fs')
local lsp = require('helpers.lsp')

vim.cmd.packadd('nvim-metals')
local conf = require('metals.config')
local validate_config = conf.validate_config

describe('metals lifecycle', function()
  local root, server, initial_buffer, initial_buffers, validations, cached_config

  local function attached(bufnr)
    return vim.lsp.get_clients({ name = 'metals', bufnr = bufnr })
  end

  local function edit(path)
    vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/' .. path))
    return vim.api.nvim_get_current_buf()
  end

  before_each(function()
    root = vim.fn.tempname()
    fs.write_file(root .. '/build.sbt', { '// build fixture' })
    server = lsp.server()
    validations = 0
    initial_buffer = vim.api.nvim_get_current_buf()
    initial_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do initial_buffers[buf] = true end
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
    cached_config = conf.get_config_cache()
    -- Keep initialize_or_attach and its real file-existence check. Replace
    -- only configuration of the external server with our in-process transport.
    conf.validate_config = function(config, bufnr)
      validations = validations + 1
      config.name = 'metals'
      config.root_dir = vim.fs.root(bufnr, 'build.sbt')
      config.cmd = server.cmd
      conf.set_config_cache(config)
      return config
    end
  end)

  after_each(function()
    lsp.stop_clients()
    vim.api.nvim_set_current_buf(initial_buffer)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if not initial_buffers[buf] then vim.api.nvim_buf_delete(buf, { force = true }) end
    end
    conf.validate_config = validate_config
    conf.set_config_cache(cached_config)
    assert.equals(0, vim.fn.delete(root, 'rf'))
  end)

  it('initializes existing Scala and sbt buffers once each, without work on switches', function()
    local expected = 0
    for _, filename in ipairs({ 'build.sbt', 'First.scala', 'Second.scala', 'plugins.sbt' }) do
      fs.write_file(root .. '/' .. filename)
      local buf = edit(filename)
      expected = expected + 1
      lsp.wait_for(function() return #attached(buf) == 1 end)
      assert.equals(expected, validations)
    end
    vim.cmd.enew()
    vim.cmd.bprevious()
    assert.equals(expected, validations)
    assert.equals(1, #server.connections)
  end)

  for _, filename in ipairs({ 'New.scala', 'new.sbt' }) do
    it('attaches ' .. filename .. ' after its first save, only once', function()
      local buf = edit(filename)
      -- Re-running setup while waiting for a save must not accumulate retries.
      require('config.metals').setup()
      require('config.metals').setup()
      assert.equals(0, #attached(buf))
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '// new source' })
      vim.cmd.write()
      lsp.wait_for(function() return #attached(buf) == 1 end)
      vim.cmd.write()
      vim.cmd.enew()
      vim.api.nvim_set_current_buf(buf)
      assert.equals(1, validations)
      assert.equals(1, #server.connections)
    end)
  end

  it('reuses an initializing workspace client when saving a new buffer', function()
    fs.write_file(root .. '/Existing.scala')
    edit('Existing.scala')
    local new = edit('New.scala')
    vim.cmd.write()
    lsp.wait_for(function() return #attached(new) == 1 end)
    assert.equals(1, #server.connections)
  end)

  it('does not attach scratch buffers or a new file changed to another filetype', function()
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(scratch, root .. '/Scratch.scala')
    vim.api.nvim_set_current_buf(scratch)
    vim.bo.filetype = 'scala'
    vim.api.nvim_exec_autocmds('BufWritePost', { buffer = scratch })
    local new = edit('New.scala')
    vim.bo[new].filetype = 'text'
    vim.cmd.write()
    assert.equals(0, validations)
    assert.equals(0, #server.connections)
  end)

  it('native restart restores loaded buffers even when focus changes', function()
    fs.write_file(root .. '/First.scala')
    fs.write_file(root .. '/Second.scala')
    local first = edit('First.scala')
    local second = edit('Second.scala')
    lsp.wait_for(function() return #attached(first) == 1 and #attached(second) == 1 end)
    local old_id = attached(first)[1].id
    vim.cmd('lsp restart')
    vim.cmd.enew()
    lsp.wait_for(function()
      local clients = attached(first)
      return #clients == 1 and clients[1].id ~= old_id and #attached(second) == 1
    end)
    assert.equals(attached(first)[1].id, attached(second)[1].id)
    assert.equals(2, #server.connections)
  end)
end)
