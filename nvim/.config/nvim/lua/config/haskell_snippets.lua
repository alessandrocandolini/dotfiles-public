local M = {}

function M.setup()
  local ls = require("luasnip")
  local s  = ls.snippet
  local t  = ls.text_node
  local i  = ls.insert_node
  local f  = ls.function_node

  local function module_name()
    local name = vim.fn.expand("%:r")
    name = name:gsub("^.*/src/", "")
    name = name:gsub("^.*/test/", "")
    name = name:gsub("^src/", "")
    name = name:gsub("^test/", "")
    name = name:gsub("/", ".")
    return name
  end

  local snippets = {
    -- 1) Module header for src/ files
    s(
      { trig = "module", name = "Haskell module header (src)" },
      {
        t("module "),
        f(module_name, {}),
        t({ " where", "", "" }),
        i(0),
      },
      {
        condition = function()
          return vim.fn.expand("%:p"):match("/src/") ~= nil
        end,
      }
    ),

    -- 2) Module header for test/ files
    s(
      { trig = "module", name = "Hspec test module (test)" },
      {
        t("module "),
        f(module_name, {}),
        t({ " where", "", "" }),
        t("import Test.Hspec"),
        t({ "", "import Test.Hspec.QuickCheck", "import Test.QuickCheck", "", "" }),
        t("spec :: Spec"),
        t({ "", "spec = do", "  " }),
        i(0),
      },
      {
        condition = function()
          return vim.fn.expand("%:p"):match("/test/") ~= nil
        end,
      }
    ),

    -- 3) it-block
    s(
      { trig = "it", name = "Hspec it block" },
      {
        t("it \""), i(1, "description"), t("\" $"),
        t({ "", "  " }), i(2, "actual"),
        t(" `shouldBe` "), i(3, "expected"),
      }
    ),

    -- 4) prop-block
    s(
      { trig = "prop", name = "QuickCheck prop block" },
      {
        t("prop \""), i(1, "description"), t("\" $"),
        t({ "", "  " }), i(2, "actual"),
        t(" `shouldBe` "), i(3, "expected"),
      }
    ),
  }

  ls.add_snippets("haskell", snippets, { key = "user_haskell_snippets" })
end

return M
