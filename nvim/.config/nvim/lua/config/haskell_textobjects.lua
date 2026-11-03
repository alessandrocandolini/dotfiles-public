local M = {}

-- Haskell stores signatures, equations, and argument-free bindings as separate
-- declarations. Expand each outer capture to the adjacent declarations of the
-- same name, within the same scope.
function M.setup()
  vim.treesitter.query.add_directive("haskell-definition!", function(match, _, source, predicate, metadata)
    local id = predicate[2]
    local node = match[id][1]
    local function name(n)
      local kind = n:type()
      if kind ~= "function" and kind ~= "bind" and kind ~= "signature" then return end
      local field = n:field("name")[1]
      if field then return vim.treesitter.get_node_text(field, source) end
    end
    local target = name(node)
    if not target then return end

    local function adjacent(n, direction)
      n = n[direction](n)
      -- Include comments only when they sit between matching declarations.
      while n and (n:type() == "comment" or n:type() == "haddock") do
        n = n[direction](n)
      end
      return n
    end
    local first, last = node, node
    local previous = adjacent(first, "prev_named_sibling")
    while previous and name(previous) == target do
      first = previous
      previous = adjacent(first, "prev_named_sibling")
    end
    local following = adjacent(last, "next_named_sibling")
    while following and name(following) == target do
      last = following
      following = adjacent(last, "next_named_sibling")
    end

    local start_row = first:range()
    local _, _, end_row, end_col = last:range()
    metadata[id] = metadata[id] or {}
    -- Outer selections are linewise; include indentation before local functions.
    metadata[id].range = { start_row, 0, end_row, end_col }
  end, { force = true })
end

return M
