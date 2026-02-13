local M = {}

local ns = vim.api.nvim_create_namespace("git_blame")
local group = vim.api.nvim_create_augroup("GitBlame", { clear = true })

local enabled = false
local inflight_blame
local inflight_root = {} -- buffer-local: bufnr -> SystemObj

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

local function git_root_async(bufnr, file, cb)
  local dir = vim.fs.dirname(file)

  local obj = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }, function(res)
    vim.schedule(function()
      -- only clear if this is still the current request for this buffer
      if inflight_root[bufnr] == obj then
        inflight_root[bufnr] = nil
      end
      if res.code ~= 0 or not res.stdout or res.stdout == "" then
        cb(nil)
      else
        cb((res.stdout:gsub("%s+$", "")))
      end
    end)
  end)

  inflight_root[bufnr] = obj
  return obj
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

  -- cancel previous root lookup for this buffer
  local old_root = inflight_root[bufnr]
  if old_root then
    pcall(function() old_root:kill(15) end)
    inflight_root[bufnr] = nil
  end

  git_root_async(bufnr, file, function(root)
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


local function open_float(lines)
  local width  = math.min(100, math.floor(vim.o.columns * 0.7))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.4))
  height = math.max(height, 3)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  local win = vim.api.nvim_open_win(bufnr, false, {
    relative = "cursor",
    row = 1,
    col = 1,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- close on “any action” that implies you’re done peeking
  local grp = vim.api.nvim_create_augroup("GitBlamePeekClose", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged", "BufLeave", "WinLeave", "InsertEnter" }, {
    group = grp,
    once = true,
    callback = function()
      close()
      -- clean up the augroup so we don't accumulate
      pcall(vim.api.nvim_del_augroup_by_id, grp)
    end,
  })
end

function M.blame_full()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then return end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return end

  local line1 = vim.api.nvim_win_get_cursor(0)[1]

  git_root_async(bufnr, file, function(root)
    if not root then
      vim.notify("Not a git repo", vim.log.levels.WARN)
      return
    end

    -- Step 1: get hash for this line
    vim.system({
      "git", "-C", root,
      "blame", "--porcelain",
      "-L", string.format("%d,+1", line1),
      file,
    }, { text = true }, function(res)
      vim.schedule(function()
        if res.code ~= 0 or not res.stdout or res.stdout == "" then
          vim.notify("git blame failed", vim.log.levels.ERROR)
          return
        end

        local first = vim.split(res.stdout, "\n", { plain = true })[1] or ""
        local hash = first:match("^(%S+)")
        if not hash or hash == "" then return end

        -- Step 2: show commit title/body like GitHub
        vim.system({
          "git", "-C", root,
          "show", "-s",
          "--date=short",
          "--format=%h%n%an · %ad%n%n%s%n%n%b",
          hash,
        }, { text = true }, function(res2)
          vim.schedule(function()
            if res2.code ~= 0 or not res2.stdout then
              vim.notify("git show failed", vim.log.levels.ERROR)
              return
            end

            local lines = vim.split(res2.stdout, "\n", { plain = true })
            open_float(lines)
          end)
        end)
      end)
    end)
  end)
end
function M.toggle()
  enabled = not enabled

  if not enabled then
    -- cancel all inflight root lookups for all buffers
    -- collect bufnrs first to avoid modifying table during iteration
    local bufnrs = {}
    for bufnr in pairs(inflight_root) do
      bufnrs[#bufnrs + 1] = bufnr
    end
    for _, bufnr in ipairs(bufnrs) do
      if inflight_root[bufnr] then
        pcall(function() inflight_root[bufnr]:kill(15) end)
        inflight_root[bufnr] = nil
      end
    end
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
      if inflight_root[args.buf] then
        pcall(function() inflight_root[args.buf]:kill(15) end)
        inflight_root[args.buf] = nil
      end
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
  vim.keymap.set("n", "<leader>gB", function()
    M.blame_full()
  end, { desc = "Git blame (full overlay)" })
end

return M
