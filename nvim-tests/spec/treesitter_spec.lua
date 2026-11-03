local keys = require('helpers.keys')

-- Keep the real ftplugins and mappings, without starting an external HLS.
vim.g.haskell_tools = { hls = { auto_attach = false } }

local scala = {
  'def process(input: Int): Int =',
  '  val validated = input + 1',
  '',
  '  val result = validated * 2',
  '',
  '  result',
  '',
  'def untouched(): Int =',
  '  42',
}
local haskell = {
  'process :: Int -> IO Int',
  'process input = do',
  '  let validated = input + 1',
  '',
  '  let result = validated * 2',
  '',
  '  pure result',
  '',
  'untouched :: Int',
  'untouched = 42',
}

describe('Tree-sitter function text objects', function()
  local initial_buffer, buffer

  local function open(lang, lines, row)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].filetype = lang
    vim.api.nvim_win_set_cursor(0, { row or 1, 0 })
  end

  before_each(function()
    initial_buffer = vim.api.nvim_get_current_buf()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
  end)

  after_each(function()
    keys.press('<Esc>')
    vim.api.nvim_set_current_buf(initial_buffer)
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  it('daf deletes an entire braceless Scala function across blank lines', function()
    open('scala', scala, 4)
    keys.press('daf')
    assert.same({ '', 'def untouched(): Int =', '  42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('vaf selects the whole Scala function from a blank line inside its body', function()
    open('scala', scala, 3)
    keys.press('vafy')
    assert.equals(table.concat(vim.list_slice(scala, 1, 6), '\n') .. '\n', vim.fn.getreg('"'))
  end)

  it('cif replaces the Scala body and preserves the declaration and next function', function()
    open('scala', scala, 4)
    keys.press('cif0<Esc>')
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.equals(scala[1], lines[1])
    assert.is_nil(table.concat(lines, '\n'):find('validated', 1, true))
    assert.equals('def untouched(): Int =', lines[#lines - 1])
    assert.equals('  42', lines[#lines])
    assert.is_false(vim.treesitter.get_parser(buffer):parse()[1]:root():has_error())
  end)

  it('daf deletes a Haskell signature and definition across blank lines', function()
    open('haskell', haskell, 5)
    keys.press('daf')
    assert.same({ '', 'untouched :: Int', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('vaf selects a Haskell signature and definition from the body', function()
    open('haskell', haskell, 5)
    keys.press('vafy')
    assert.equals(table.concat(vim.list_slice(haskell, 1, 7), '\n') .. '\n', vim.fn.getreg('"'))
  end)

  it('cif changes a Haskell body while preserving the signature and following definition', function()
    open('haskell', haskell, 5)
    keys.press('cifpure input<Esc>')
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.equals(haskell[1], lines[1])
    assert.equals('process input = pure input', lines[2])
    assert.is_nil(table.concat(lines, '\n'):find('validated', 1, true))
    assert.equals('untouched :: Int', lines[#lines - 1])
    assert.equals('untouched = 42', lines[#lines])
    assert.is_false(vim.treesitter.get_parser(buffer):parse()[1]:root():has_error())
  end)


  local where_binding = {
    'runInstructions :: [Int] -> Int',
    'runInstructions = sum . map runInstruction',
    '  where',
    '    runInstruction :: Int -> Int',
    '    runInstruction i = i + 1',
    '',
    'untouched :: Int',
    'untouched = 42',
  }

  for _, row in ipairs({ 1, 2, 3 }) do
    it('daf removes a binding with where, from line ' .. row .. ', including its signature', function()
      open('haskell', where_binding, row)
      keys.press('daf')
      assert.same({ '', 'untouched :: Int', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
    end)
  end

  it('daf inside a local where helper removes only that helper and its signature', function()
    open('haskell', where_binding, 5)
    keys.press('daf')
    assert.same({
      where_binding[1], where_binding[2], '  where', '',
      'untouched :: Int', 'untouched = 42',
    }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('cif replaces an argument-free binding body and keeps its where definitions', function()
    open('haskell', where_binding, 2)
    keys.press('cifconst 0<Esc>')
    local expected = vim.deepcopy(where_binding)
    expected[2] = 'runInstructions = const 0'
    assert.same(expected, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('daf groups all equations with the same signature and preserves the next declaration', function()
    open('haskell', {
      'isSampleCycle :: Int -> Bool',
      'isSampleCycle 20 = True',
      '',
      '-- The remaining cycles.',
      'isSampleCycle n = (n - 20) `mod` 40 == 0',
      '',
      'untouched :: Int',
      'untouched = 42',
    }, 5)
    keys.press('daf')
    assert.same({ '', 'untouched :: Int', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('daf handles guards and where on a function with arguments', function()
    open('haskell', {
      'process :: Int -> Int',
      'process x',
      '  | x > 0 = step x',
      '  | otherwise = 0',
      '  where',
      '    step y = y + 1',
      '',
      'untouched = 42',
    }, 5)
    keys.press('daf')
    assert.same({ '', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('daf groups equations without requiring a type signature', function()
    open('haskell', { 'process 0 = 1', 'process x = x + 1', '', 'untouched = 42' }, 2)
    keys.press('daf')
    assert.same({ '', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('daf handles a single binding without arguments or where', function()
    open('haskell', { 'initial :: Int', 'initial = 42', '', 'untouched = 42' }, 2)
    keys.press('daf')
    assert.same({ '', 'untouched = 42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  for lang, lines in pairs({
    lua = { 'local function example()', '  return 42', 'end' },
    rust = { 'fn example() -> i32 {', '    42', '}' },
    nix = { '{ example = x: x + 1; }' },
  }) do
    it('loads ' .. lang .. ' function text objects without Tree-sitter highlighting', function()
      open(lang, lines)
      vim.api.nvim_win_set_cursor(0, { 1, lang == 'nix' and 15 or 0 })
      keys.press('yaf')
      assert.is_truthy(vim.fn.getreg('"'):find('example', 1, true))
      assert.is_nil(vim.treesitter.highlighter.active[buffer])
    end)
  end

  it('keeps function objects when highlighting is disabled', function()
    open('scala', scala, 4)
    assert.is_nil(vim.treesitter.highlighter.active[buffer])
    keys.press('daf')
    assert.same({ '', 'def untouched(): Int =', '  42' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)
end)
