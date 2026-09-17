local fs = require('helpers.fs')

-- Exercise the real FileType -> ftplugin -> config path, but never start a JVM
-- or ask nvim-metals to install/import anything in these regression tests.
vim.cmd.packadd('nvim-metals')
local metals = require('metals')
local initialize_or_attach = metals.initialize_or_attach

describe('metals attachment', function()
  local root, calls, initial_buffer, initial_buffers, initial_autocmds

  local function open_file(path, filetype)
    local filename = root .. '/' .. path
    fs.write_file(filename, { '// attachment fixture' })
    vim.cmd('edit ' .. vim.fn.fnameescape(filename))
    assert.equals(filetype, vim.bo.filetype)
    return vim.api.nvim_get_current_buf()
  end

  before_each(function()
    root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    calls = {}
    initial_buffer = vim.api.nvim_get_current_buf()
    initial_buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      initial_buffers[bufnr] = true
    end
    -- :edit can reuse an empty unnamed buffer; keep the original buffer intact
    -- so cleanup never returns to a fixture whose directory has been deleted.
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
    initial_autocmds = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = 'FileType' })) do
      if autocmd.id then
        initial_autocmds[autocmd.id] = true
      end
    end
    metals.initialize_or_attach = function()
      table.insert(calls, vim.api.nvim_get_current_buf())
    end
  end)

  after_each(function()
    -- Also clean up callbacks left by the buggy implementation, so a failed
    -- assertion cannot start the real server or contaminate the next test.
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = 'FileType' })) do
      if autocmd.id and not initial_autocmds[autocmd.id] then
        vim.api.nvim_del_autocmd(autocmd.id)
      end
    end
    vim.api.nvim_set_current_buf(initial_buffer)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if not initial_buffers[bufnr] then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    metals.initialize_or_attach = initialize_or_attach
    assert.equals(0, vim.fn.delete(root, 'rf'))
  end)

  it('initializes each newly opened Scala buffer exactly once', function()
    local expected = {}
    for _, filename in ipairs({ 'First.scala', 'Second.scala', 'Third.scala' }) do
      table.insert(expected, open_file(filename, 'scala'))
      assert.same(expected, calls)
    end
  end)

  it('initializes an sbt-first session and mixed Scala/sbt buffers exactly once', function()
    local expected = {}
    for _, file in ipairs({
      { 'build.sbt', 'sbt' },
      { 'src/main/scala/Main.scala', 'scala' },
      { 'project/plugins.sbt', 'sbt' },
    }) do
      table.insert(expected, open_file(file[1], file[2]))
      assert.same(expected, calls)
    end
  end)

  it('does not reinitialize on buffer switches or attach unrelated filetypes', function()
    local scala = open_file('Main.scala', 'scala')
    open_file('notes.txt', 'text')
    vim.api.nvim_set_current_buf(scala)
    assert.same({ scala }, calls)
  end)
end)
