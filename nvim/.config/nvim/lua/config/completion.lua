local M = {}

local function word_before_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return vim.fn.matchstr(vim.api.nvim_get_current_line():sub(1, col), [[\k*$]])
end

local function expand(item)
  local body = type(item.user_data) == "table" and item.user_data.local_snippet
  if not body then return end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- Only replace the accepted trigger, never adjacent text.
  if vim.api.nvim_get_current_line():sub(col - #item.word + 1, col) ~= item.word then return end
  vim.api.nvim_buf_set_text(0, row - 1, col - #item.word, row - 1, col, { "" })
  vim.snippet.expand(body)
end

-- A local 'completefunc' source; no server, cache, or asynchronous work.
function M.complete_snippets(findstart, base, snippets)
  if findstart == 1 then
    return vim.api.nvim_win_get_cursor(0)[2] - #word_before_cursor()
  end
  local items = {}
  for _, snippet in ipairs(snippets) do
    items[#items + 1] = {
      word = snippet.trigger,
      menu = snippet.description,
      kind = "Snippet",
      info = snippet.body,
      user_data = { local_snippet = snippet.body },
    }
  end
  return base == "" and items or vim.fn.matchfuzzy(items, base, { key = "word" })
end

function M.setup()
  vim.opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy", "preselect" }
  vim.opt.complete = { "F", "o" } -- local snippets, then LSP omnifunc
  vim.opt.autocomplete = true
  vim.opt.autocompletedelay = 60

  vim.api.nvim_create_autocmd("CompleteDone", {
    group = vim.api.nvim_create_augroup("LocalSnippets", { clear = true }),
    callback = function()
      if vim.v.event.reason == "accept" then expand(vim.v.completed_item) end
    end,
  })

  vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
      return vim.keycode(vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>" or "<C-y>")
    end
    return require("nvim-autopairs").autopairs_cr()
  end, { expr = true, replace_keycodes = false, silent = true, desc = "Accept completion or insert newline" })
  vim.keymap.set("i", "<C-Space>", function()
    return vim.fn.pumvisible() == 1 and "<C-e><C-n>" or "<C-n>"
  end, { expr = true, desc = "Complete snippets and LSP" })
  vim.keymap.set("i", "<Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
  end, { expr = true, desc = "Next completion or indent" })
  vim.keymap.set("i", "<S-Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
  end, { expr = true, desc = "Previous completion" })
  vim.keymap.set({ "i", "s" }, "<C-k>", function()
    if vim.snippet.active({ direction = 1 }) then
      vim.snippet.jump(1)
    elseif type(vim.bo.completefunc) == "function" then
      local word = word_before_cursor()
      for _, item in ipairs(vim.bo.completefunc(0, word)) do
        if item.word == word then expand(item); break end
      end
    end
  end, { silent = true, desc = "Expand snippet or next placeholder" })
  vim.keymap.set({ "i", "s" }, "<C-j>", function()
    if vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1) end
  end, { silent = true, desc = "Previous snippet placeholder" })
end

return M
