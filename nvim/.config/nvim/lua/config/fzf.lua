local M = {}

local function open_selection(selected, opts)
  local actions = require("fzf-lua.actions")

  if #selected ~= 1 then
    return actions.file_edit_or_qf(selected, opts)
  end

  local target = require("fzf-lua.path").entry_to_file(selected[1], opts, opts._uri).path

  if not target then
    return actions.file_edit(selected, opts)
  end

  target = vim.fn.fnamemodify(target, ":p")

  if vim.fn.isdirectory(target) == 1 then
    vim.schedule(function()
      require("oil").open(target)
    end)
    return
  end

  return actions.file_edit(selected, opts)
end

function M.setup()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify(
      "fzf-lua is not installed or failed to load",
      vim.log.levels.WARN,
      { title = "Config" }
    )
    return
  end

  fzf.setup({
    winopts = {
      split = "belowright 20new",
      preview = { hidden = true }
    },
    files = {
      file_icons = false,
      git_icons = false,
    },
    fzf_opts = {
      ["--info"]   = "inline",
      ["--layout"] = "default",
    },
    keymap = {
      fzf = {
        ["ctrl-_"] = "toggle-preview",
        ["ctrl-p"] = "abort",
        ["ctrl-q"] = "select-all+accept",
        ["ctrl-l"] = "clear-query",
      },
    },
    grep = {
      rg_opts = table.concat({
        "--column",
        "--line-number",
        "--no-heading",
        "--color=always",
        "--smart-case",
        "--hidden",
        "--glob=!.git/*",
      }, " "),
    },
  })

  local function find_files(resume)
    local cmd = 'fd --color=never --hidden --type f --type l --type d --exclude .git'
    local base = vim.fn.fnamemodify(vim.fn.expand('%'), ':h:.:S')
    if base ~= '.' then
      cmd = cmd .. (" | proximity-sort %s"):format(vim.fn.shellescape(vim.fn.expand('%')))
    end
    fzf.files({
      cmd = cmd,
      resume = resume,
      actions = {
        ["enter"] = open_selection,
      },
      fzf_opts = {
        ['--scheme']   = 'path',
        ['--tiebreak'] = 'index',
      }
    })
  end

  vim.keymap.set("n", "<C-p>", function() find_files(false) end, { silent = true, desc = "Find files" })
  vim.keymap.set("n", "<Leader>p", function() find_files(true) end, { silent = true, desc = "Resume file search" })
  vim.keymap.set("n", "<Leader>r", fzf.live_grep, { silent = true, desc = "Search project (live grep)" })

  local function search_word_under_cursor()
    local w = vim.fn.expand("<cword>")
    if w and w ~= "" then
      fzf.grep_cword()
    end
  end

  vim.keymap.set("n", "grw", search_word_under_cursor, { silent = true, desc = "Search word under cursor" })
end

return M
