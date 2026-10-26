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
    if kind == 'src' or kind == 'test' then
      local name = vim.fn.fnamemodify(vim.fs.relpath(dir, path), ':r'):gsub('/', '.')
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

function M.setup()
  vim.bo.completefunc = function(findstart, base)
    return require("config.completion").complete_snippets(findstart, base, snippets())
  end
  vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. " | setlocal completefunc<"
end

return M
