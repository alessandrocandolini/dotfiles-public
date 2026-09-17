local fs = require('helpers.fs')
local lsp = require('helpers.lsp')

describe('Haskell attachment', function()
  after_each(lsp.stop_clients)

  it('attaches the first Haskell buffer and reuses its client for the second', function()
    local server = lsp.server()
    -- Each spec runs in its own Neovim process with the real bootstrap.
    -- Replace only the external server, preserving plugin loading and startup.
    vim.g.haskell_tools = { hls = { auto_attach = true, cmd = { 'nvim' } } }
    vim.lsp.config('haskell-tools.nvim', { cmd = server.cmd })
    fs.with_temp_project({
      ['cabal.project'] = { 'packages: .' },
      ['First.hs'] = { 'module First where' },
      ['Second.hs'] = { 'module Second where' },
    }, function(root)
      for _, filename in ipairs({ 'First.hs', 'Second.hs' }) do
        vim.cmd.edit(root .. '/' .. filename)
        local buf = vim.api.nvim_get_current_buf()
        lsp.wait_for(function()
          return #vim.lsp.get_clients({ name = 'haskell-tools.nvim', bufnr = buf }) == 1
        end)
        assert.equals(1, #server.connections)
      end
      assert.equals(vim.uv.fs_realpath(root), vim.lsp.get_clients({ name = 'haskell-tools.nvim' })[1].root_dir)
    end)
  end)
end)
