local M = {}

local ns = vim.api.nvim_create_namespace("git_blame")
local group = vim.api.nvim_create_augroup("GitBlame", { clear = true })

local enabled = false
local inflight_blame
local inflight_root

local function clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function set_virt(bufnr, lnum0, msg)
  clear(bufnr)
  vim.api.nvim_buf_set_extmark(bufnr, ns, lnum0, 0, {
    virt_text = { { msg, "Comment" } },
    virt_text_pos = "eol",
    hl_mode = "combine",
  })
end

local function parse_porcelain(stdout)
  local lines = vim.split(stdout or "", "\n", { plain = true })
  if not lines[1] or lines[1] == "" then return nil end

  local hash = lines[1]:match("^(%S+)") or "????????"
  local author, atime, summary = "?", nil, ""

  for i = 2, #lines do
    local l = lines[i]
    if l == "" then break end
    if l:sub(1, 7) == "author " then author = l:sub(8)
    elseif l:sub(1, 12) == "author-time " then atime = tonumber(l:sub(13))
    elseif l:sub(1, 8) == "summary " then summary = l:sub(9)
    end
  end

  local date = atime and os.date("%Y-%m-%d", atime) or "????-??-??"
  return string.format("%s %s · %s · %s", hash:sub(1, 8), author, date, summary)
end

local function git_root_async(file, cb)
  local dir = vim.fs.dirname(file)

  inflight_root = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or not res.stdout or res.stdout == "" then
        cb(nil)
      else
        cb((res.stdout:gsub("%s+$", "")))
      end
    end)
  end)
end

local function blame()
  if not enabled then return end

  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then return end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return end

  local line1 = vim.api.nvim_win_get_cursor(0)[1]
  local lnum0 = line1 - 1

  -- cancel previous blame request
  if inflight_blame then
    pcall(function() inflight_blame:kill(15) end)
    inflight_blame = nil
  end

  -- cancel previous root lookup
  if inflight_root then
    pcall(function() inflight_root:kill(15) end)
    inflight_root = nil
  end

  git_root_async(file, function(root)
    if not enabled then return end
    if not root then
      clear(bufnr)
      return
    end

    -- if cursor moved while we were resolving root, don't do stale work
    if vim.api.nvim_get_current_buf() ~= bufnr then return end
    if vim.api.nvim_win_get_cursor(0)[1] ~= line1 then return end

    inflight_blame = vim.system({
      "git", "-C", root,
      "blame", "--porcelain",
      "-L", string.format("%d,+1", line1),
      "--",
      file,
    }, { text = true }, function(res)
      vim.schedule(function()
        inflight_blame = nil
        if not enabled then return end
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        if vim.api.nvim_get_current_buf() ~= bufnr then return end
        if vim.api.nvim_win_get_cursor(0)[1] ~= line1 then return end
        if res.code ~= 0 then clear(bufnr); return end

        local msg = parse_porcelain(res.stdout)
        if not msg then clear(bufnr); return end
        set_virt(bufnr, lnum0, msg)
      end)
    end)
  end)
end

function M.toggle()
  enabled = not enabled

  if not enabled then
    if inflight_root then pcall(function() inflight_root:kill(15) end); inflight_root = nil end
    if inflight_blame then pcall(function() inflight_blame:kill(15) end); inflight_blame = nil end
    clear(vim.api.nvim_get_current_buf())
    vim.api.nvim_clear_autocmds({ group = group })
    return
  end

  vim.api.nvim_clear_autocmds({ group = group })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = blame,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = group,
    callback = function(args)
      if inflight_root then pcall(function() inflight_root:kill(15) end); inflight_root = nil end
      if inflight_blame then pcall(function() inflight_blame:kill(15) end); inflight_blame = nil end
      clear(args.buf)
    end,
  })

  blame()
end

function M.setup()
  vim.keymap.set("n", "<leader>gb", function()
    M.toggle()
  end, { desc = "Git blame (minimal async)" })
end

return M
