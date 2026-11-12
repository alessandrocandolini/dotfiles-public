local M = {}

local function module_path()
  local path = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(path, function(name)
    return name == 'cabal.project' or name == 'stack.yaml' or name == 'package.yaml'
      or name == '.git' or name:match('%.cabal$') ~= nil
  end)
  -- Use the closest source directory, without crossing the package/project root.
  for dir in vim.fs.parents(path) do
    if dir == root then break end
    local kind = vim.fs.basename(dir)
    local relative = vim.fs.relpath(dir, path)
    if relative and (kind == 'src' or kind == 'test') then
      local name = vim.fn.fnamemodify(relative, ':r'):gsub('/', '.')
      return kind, name
    end
  end
end

local function snippets()
  local items = {
    {
      trigger = "it",
      description = "Hspec it block",
      body = [[it "${1:description}" \$
  ${2:actual} `shouldBe` ${3:expected}$0]],
    },
    {
      trigger = "prop",
      description = "QuickCheck prop block",
      body = [[prop "${1:description}" \$
  ${2:actual} `shouldBe` ${3:expected}$0]],
    },
  }
  local kind, name = module_path()
  if kind == "src" then
    items[#items + 1] = {
      trigger = "module",
      description = "Haskell module header (src)",
      body = "module " .. name .. " where\n\n$0",
    }
  elseif kind == "test" then
    items[#items + 1] = {
      trigger = "module",
      description = "Hspec test module (test)",
      body = "module " .. name .. " where\n\n"
        .. "import Test.Hspec\nimport Test.Hspec.QuickCheck\nimport Test.QuickCheck\n\n"
        .. "spec :: Spec\nspec = do\n  $0",
    }
  end
  return items
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_completions(_, callback)
  local items = {}
  for index, snippet in ipairs(snippets()) do
    items[#items + 1] = {
      label = snippet.trigger,
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertText = snippet.body,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      labelDetails = { description = snippet.description },
      documentation = { kind = 'markdown', value = snippet.body },
      sortText = string.format('%03d', index),
    }
  end
  callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
end

return M
