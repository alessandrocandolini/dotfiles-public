local M = {}

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
        ["ctrl-p"] = "toggle-preview",
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
      fzf_opts = {
        ['--scheme']   = 'path',
        ['--tiebreak'] = 'index',
      }
    })
  end

  vim.keymap.set("n", "<C-p>", function() find_files(true) end, { silent = true, desc = "Find files" })
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
