-- Build hook for make nvim-sync; never runs during editor startup.
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local languages = dofile(config_dir .. "/treesitter.lua").languages

local ok, err = xpcall(function()
  for _, executable in ipairs({ "tree-sitter", "cc", "curl", "tar" }) do
    assert(vim.fn.executable(executable) == 1, "Tree-sitter sync requires " .. executable .. " on PATH")
  end
  vim.cmd.packadd("nvim-treesitter")
  vim.cmd.packadd("nvim-treesitter-textobjects")
  local ts = require("nvim-treesitter")
  ts.setup({})
  assert(ts.install(languages):wait(300000), "Tree-sitter parser installation failed")
  -- update uses the parser revisions from the locked plugin, including downgrades.
  assert(ts.update(languages):wait(300000), "Tree-sitter parser update failed")
  for _, lang in ipairs(languages) do
    assert(vim.treesitter.language.add(lang), "Cannot load parser: " .. lang)
    assert(vim.treesitter.query.get(lang, "textobjects"), "Missing text objects: " .. lang)
    assert(vim.treesitter.query.get(lang, "highlights"), "Missing highlights: " .. lang)
  end
end, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
