local M = {}

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
  local path = vim.fn.expand("%:p")
  local name = vim.fn.expand("%:r")
    :gsub("^.*/src/", ""):gsub("^.*/test/", "")
    :gsub("^src/", ""):gsub("^test/", ""):gsub("/", ".")
  if path:match("/src/") then
    items[#items + 1] = {
      trigger = "module",
      description = "Haskell module header (src)",
      body = "module " .. name .. " where\n\n$0",
    }
  elseif path:match("/test/") then
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
