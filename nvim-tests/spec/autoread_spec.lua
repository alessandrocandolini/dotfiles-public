local fs = require('helpers.fs')

describe('native autoread', function()
  local root, path, buf, initial_buffer

  local function wait_for_text(text)
    assert(vim.wait(3000, function()
      return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == text
    end, 20), 'expected native autoread to load external text')
  end

  before_each(function()
    initial_buffer = vim.api.nvim_get_current_buf()
    -- :edit can reuse the current unnamed buffer; keep the original buffer intact for cleanup.
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
    root = vim.fn.tempname()
    path = root .. '/watched.txt'
    fs.write_file(path, { 'original' })
    vim.cmd.edit(path)
    buf = vim.api.nvim_get_current_buf()
  end)

  after_each(function()
    vim.api.nvim_set_current_buf(initial_buffer)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    assert.equals(0, vim.fn.delete(root, 'rf'))
  end)

  it('reloads an external edit without a buffer switch or focus event', function()
    fs.write_file(path, { 'changed outside the editor' })
    wait_for_text('changed outside the editor')
    assert.is_false(vim.bo[buf].modified)
  end)

  it('reloads an atomic replacement and keeps watching the new file', function()
    local replacement = root .. '/replacement.txt'
    fs.write_file(replacement, { 'atomic replacement' })
    assert(vim.uv.fs_rename(replacement, path))
    wait_for_text('atomic replacement')

    fs.write_file(path, { 'another external edit after replacement' })
    wait_for_text('another external edit after replacement')
  end)

  it('preserves unsaved edits when the file changes externally', function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'unsaved buffer edit' })
    local checked = false
    vim.api.nvim_create_autocmd('FileChangedShellPost', {
      buffer = buf,
      once = true,
      callback = function() checked = true end,
    })
    fs.write_file(path, { 'conflicting external edit' })
    assert(vim.wait(3000, function() return checked end, 20), 'expected external change detection')
    assert.same({ 'unsaved buffer edit' }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.is_true(vim.bo[buf].modified)
    assert.same({ 'conflicting external edit' }, vim.fn.readfile(path))
  end)
end)
