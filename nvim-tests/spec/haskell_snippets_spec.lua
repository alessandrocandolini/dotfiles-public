local fs = require('helpers.fs')
local ls = require('luasnip')
local source = require('cmp_luasnip').new()

-- Exercise the real ftplugin and completion source without starting HLS.
vim.g.haskell_tools = { hls = { auto_attach = false } }

local function module_completions()
  local items
  source:complete({ option = {}, context = { cursor_before_line = 'module' } }, function(result)
    items = vim.tbl_filter(function(item) return item.label == 'module' end, result)
  end)
  return items
end

local function expand_named(name)
  for _, snippet in ipairs(ls.get_snippets('haskell')) do
    if snippet.name == name then
      ls.snip_expand(snippet)
      return vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end
  end
  error('missing snippet: ' .. name)
end

describe('Haskell snippets', function()
  after_each(function()
    vim.cmd('stopinsert')
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == 'haskell' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end)

  it('offers only the appropriate module header in source and test files', function()
    fs.with_temp_project({
      ['src/Foo.hs'] = { '' },
      ['test/FooSpec.hs'] = { '' },
      ['app/Main.hs'] = { '' },
    }, function(root)
      for _, case in ipairs({
        { 'src/Foo.hs', 'Haskell module header (src)' },
        { 'test/FooSpec.hs', 'Hspec test module (test)' },
        { 'app/Main.hs' },
      }) do
        vim.cmd.edit(root .. '/' .. case[1])
        local items = module_completions()
        assert.equals(case[2] and 1 or 0, #items)
        if case[2] then
          assert.equals(case[2], ls.get_id_snippet(items[1].data.snip_id).name)
        end
      end
    end)
  end)

  for _, case in ipairs({
    { 'src/Foo/Bar.hs', 'Haskell module header (src)', 'Foo.Bar' },
    { 'test/Foo/BarSpec.hs', 'Hspec test module (test)', 'Foo.BarSpec' },
  }) do
    it('keeps the module name when cwd is inside ' .. case[1], function()
      fs.with_temp_project({ [case[1]] = { '' } }, function(root)
        vim.cmd.edit(root .. '/' .. case[1])
        vim.cmd.cd(vim.fs.dirname(root .. '/' .. case[1]))
        assert.equals('module ' .. case[3] .. ' where', expand_named(case[2])[1])
      end)
    end)
  end

  for _, case in ipairs({ { 'it', 'Hspec it block' }, { 'prop', 'QuickCheck prop block' } }) do
    it('expands ' .. case[1] .. ' with valid string quotes', function()
      fs.with_temp_project({ ['test/FooSpec.hs'] = { '' } }, function(root)
        vim.cmd.edit(root .. '/test/FooSpec.hs')
        assert.same({
          case[1] .. ' "description" $',
          '  actual `shouldBe` expected',
        }, expand_named(case[2]))
      end)
    end)
  end
end)
