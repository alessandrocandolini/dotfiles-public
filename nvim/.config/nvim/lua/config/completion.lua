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
  if (base == "" or not M.typing) and not M.manual then return {} end
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
  vim.g.completion_esc_discards = true

  local group = vim.api.nvim_create_augroup("LocalSnippets", { clear = true })
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = group,
    callback = function()
      if vim.v.event.reason == "accept" then expand(vim.v.completed_item) end
    end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function() M.typing = false end,
  })
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = group,
    callback = function() M.typing = true end,
  })

  vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
      if vim.fn.complete_info({ "selected" }).selected ~= -1 then return vim.keycode("<C-y>") end
      return vim.keycode("<C-e>") .. require("nvim-autopairs").autopairs_cr()
    end
    return require("nvim-autopairs").autopairs_cr()
  end, { expr = true, replace_keycodes = false, silent = true, desc = "Accept selected completion or insert newline" })
  local function complete_manually()
    if vim.fn.pumvisible() == 1 then return "<C-n>" end
    M.manual = true
    vim.schedule(function() M.manual = false end)
    return vim.fn.complete_info({ "mode" }).mode ~= "" and "<C-e><C-n>" or "<C-n>"
  end
  vim.keymap.set("i", "<Esc>", function()
    if vim.fn.pumvisible() == 1 and vim.g.completion_esc_discards then return "<C-e><Esc>" end
    return "<Esc>"
  end, { expr = true, desc = "Leave insert mode, discarding the highlighted completion unless g:completion_esc_discards is false" })
  vim.keymap.set("i", "<C-Space>", complete_manually, { expr = true, desc = "Complete snippets and LSP, or next item" })
  vim.keymap.set("i", "<Nul>", complete_manually, { expr = true, desc = "Complete snippets and LSP, or next item" })
  vim.keymap.set("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then return "<C-n>" end
    if vim.snippet.active({ direction = 1 }) then return "<Cmd>lua vim.snippet.jump(1)<CR>" end
    return "<Tab>"
  end, { expr = true, desc = "Next completion, snippet placeholder, or indent" })
  vim.keymap.set("i", "<S-Tab>", function()
    if vim.fn.pumvisible() == 1 then return "<C-p>" end
    if vim.snippet.active({ direction = -1 }) then return "<Cmd>lua vim.snippet.jump(-1)<CR>" end
    return "<S-Tab>"
  end, { expr = true, desc = "Previous completion or snippet placeholder" })
end

return M
