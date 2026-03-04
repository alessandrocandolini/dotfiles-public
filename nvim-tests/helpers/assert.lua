local M = {}

local function inspect_value(v)
  if vim and vim.inspect then
    return vim.inspect(v)
  end
  return tostring(v)
end

local function fail(message)
  error(message, 3)
end

function M.expect(actual)
  local matcher = {}

  function matcher.to_equal(expected)
    local equal = false
    if vim and vim.deep_equal then
      equal = vim.deep_equal(actual, expected)
    else
      equal = actual == expected
    end

    if not equal then
      fail(string.format(
        'expected %s, got %s',
        inspect_value(expected),
        inspect_value(actual)
      ))
    end
  end

  function matcher.to_be_truthy()
    if not actual then
      fail('expected truthy value, got ' .. inspect_value(actual))
    end
  end

  function matcher.to_match(pattern)
    if type(actual) ~= 'string' then
      fail('to_match expects a string, got ' .. type(actual))
    end
    if not string.match(actual, pattern) then
      fail(string.format('expected %q to match pattern %q', actual, pattern))
    end
  end

  function matcher.to_error_matching(pattern)
    if type(actual) ~= 'function' then
      fail('to_error_matching expects a function, got ' .. type(actual))
    end

    local ok, err = pcall(actual)
    if ok then
      fail('expected function to raise an error, but it succeeded')
    end

    local msg = tostring(err)
    if pattern and not string.match(msg, pattern) then
      fail(string.format('expected error %q to match pattern %q', msg, pattern))
    end
  end

  return matcher
end

return M
