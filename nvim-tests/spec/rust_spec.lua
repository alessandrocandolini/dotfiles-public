local fs = require('helpers.fs')
local lsp = require('helpers.lsp')

local function package_manifest(name)
  return { '[package]', 'name = "' .. name .. '"', 'version = "0.1.0"', 'edition = "2021"' }
end

describe('Rust workspace attachment', function()
  local server

  before_each(function()
    assert.equals(1, vim.fn.executable('cargo'), 'the test shell must provide Cargo')
    server = lsp.server()
    vim.lsp.config('rust-analyzer', { cmd = server.cmd })
    vim.lsp.enable('rust-analyzer')
  end)

  after_each(function()
    vim.lsp.enable('rust-analyzer', false)
    lsp.stop_clients()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == 'rust' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end)

  local function open_files(root, filenames)
    local buffers = {}
    for _, filename in ipairs(filenames) do
      vim.cmd.edit(root .. '/' .. filename)
      buffers[#buffers + 1] = vim.api.nvim_get_current_buf()
    end
    lsp.wait_for(function()
      for _, buf in ipairs(buffers) do
        if #vim.lsp.get_clients({ name = 'rust-analyzer', bufnr = buf }) ~= 1 then return false end
      end
      return true
    end)
    return buffers
  end

  it('reuses one client for two members of a Cargo workspace', function()
    fs.with_temp_project({
      ['Cargo.toml'] = { '[workspace]', 'members = ["a", "b"]', 'resolver = "2"' },
      ['a/Cargo.toml'] = package_manifest('a'),
      ['a/src/lib.rs'] = { 'pub fn a() {}' },
      ['b/Cargo.toml'] = package_manifest('b'),
      ['b/src/lib.rs'] = { 'pub fn b() {}' },
    }, function(root)
      open_files(root, { 'a/src/lib.rs', 'b/src/lib.rs' })
      assert.equals(1, #server.connections)
      assert.equals(vim.uv.fs_realpath(root), vim.lsp.get_clients({ name = 'rust-analyzer' })[1].root_dir)
    end)
  end)

  it('keeps independent crates in the same repository separate', function()
    fs.with_temp_project({
      ['.git/HEAD'] = { 'ref: refs/heads/main' },
      ['a/Cargo.toml'] = package_manifest('a'),
      ['a/src/lib.rs'] = { '' },
      ['b/Cargo.toml'] = package_manifest('b'),
      ['b/src/lib.rs'] = { '' },
    }, function(root)
      local buffers = open_files(root, { 'a/src/lib.rs', 'b/src/lib.rs' })
      assert.equals(2, #server.connections)
      for index, member in ipairs({ 'a', 'b' }) do
        local client = vim.lsp.get_clients({ name = 'rust-analyzer', bufnr = buffers[index] })[1]
        assert.equals(vim.uv.fs_realpath(root .. '/' .. member), client.root_dir)
      end
    end)
  end)

  it('still attaches at the crate when Cargo rejects a manifest being edited', function()
    fs.with_temp_project({
      ['Cargo.toml'] = { '[package' },
      ['src/lib.rs'] = { '' },
    }, function(root)
      open_files(root, { 'src/lib.rs' })
      assert.equals(vim.uv.fs_realpath(root), vim.lsp.get_clients({ name = 'rust-analyzer' })[1].root_dir)
    end)
  end)

  it('preserves rust-project.json roots for non-Cargo projects', function()
    fs.with_temp_project({
      ['rust-project.json'] = { '{"crates":[]}' },
      ['src/lib.rs'] = { '' },
    }, function(root)
      open_files(root, { 'src/lib.rs' })
      assert.equals(vim.uv.fs_realpath(root), vim.lsp.get_clients({ name = 'rust-analyzer' })[1].root_dir)
    end)
  end)
end)
