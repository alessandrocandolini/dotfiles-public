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
      ["--info"] = "inline",
      ["--layout"]    = "default",
    },
    keymap = {
      fzf = {
        ["ctrl-p"] = "toggle-preview",
        ["ctrl-q"] = "select-all+accept",
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

  vim.keymap.set("n", "<Leader>f", function()
    local cmd = 'fd --color=never --hidden --type f --type l --exclude .git'
    local base = vim.fn.fnamemodify(vim.fn.expand('%'), ':h:.:S')
    if base ~= '.' then
      cmd = cmd .. (" | proximity-sort %s"):format(vim.fn.shellescape(vim.fn.expand('%')))
    end
    fzf.files({
      cmd = cmd,
      fzf_opts = {
        ['--scheme']    = 'path',
        ['--tiebreak']  = 'index',
      }
    })
  end, { silent = true })

  vim.keymap.set("n", "<Leader>r", function()
    fzf.live_grep()
  end, { silent = true })

  vim.keymap.set("n", "grw", function()
    local w = vim.fn.expand("<cword>")
    if w == nil or w == "" then
      return
    else
      fzf.grep_cword()
    end
  end, { silent = true })

end

return M

