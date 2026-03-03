local M = {}

local inflight = {} -- buffer-local inflight job handles

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function open_history_window(title, lines)
  local width = math.max(80, math.floor(vim.o.columns * 0.9))
  local height = math.min(math.max(12, #lines + 2), math.floor(vim.o.lines * 0.6))

  vim.cmd("botright " .. tostring(height) .. "split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype = "git"

  local payload = {
    title,
    string.rep("-", math.min(width, math.max(20, #title))),
  }
  for _, l in ipairs(lines) do
    table.insert(payload, l)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].modified = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = false
end

local function git_root_async(bufnr, file, cb)
  local dir = vim.fs.dirname(file)

  local handle = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }, function(res)
    vim.schedule(function()
      if inflight[bufnr] == handle then
        inflight[bufnr] = nil
      end
      if res.code ~= 0 or not res.stdout or res.stdout == "" then
        cb(nil)
      else
        cb((res.stdout:gsub("%s+$", "")))
      end
    end)
  end)

  inflight[bufnr] = handle
end

local function relpath_under_root(file, root)
  local norm_root = root:gsub("/+$", "")
  if file:sub(1, #norm_root + 1) == norm_root .. "/" then
    return file:sub(#norm_root + 2)
  end
  return nil
end

local function line_history()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then
    notify("Line history works only in file buffers", vim.log.levels.WARN)
    return
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    notify("Current buffer has no file on disk", vim.log.levels.WARN)
    return
  end

  local line1 = vim.api.nvim_win_get_cursor(0)[1]

  if inflight[bufnr] then
    pcall(function() inflight[bufnr]:kill(15) end)
    inflight[bufnr] = nil
  end

  git_root_async(bufnr, file, function(root)
    if not root then
      notify("Not a git repository", vim.log.levels.WARN)
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    if vim.api.nvim_get_current_buf() ~= bufnr then return end

    local rel = relpath_under_root(file, root)
    if not rel then
      notify("File is not under repository root", vim.log.levels.ERROR)
      return
    end

    local handle = vim.system({
      "git", "-C", root,
      "log", "--color=never", "--date=iso-strict", "--decorate=full",
      "--pretty=format:================================================================================%ncommit %H%nparents %P%nauthor %an <%ae>%nauthor-date %aI%ncommitter %cn <%ce>%ncommitter-date %cI%ndecorations %D%n%nsubject:%n%s%n%nbody:%n%B",
      "-L", string.format("%d,%d:%s", line1, line1, rel),
    }, { text = true }, function(res)
      vim.schedule(function()
        if inflight[bufnr] == handle then
          inflight[bufnr] = nil
        end

        if not vim.api.nvim_buf_is_valid(bufnr) then return end

        if res.code ~= 0 then
          local err = (res.stderr or ""):gsub("%s+$", "")
          if err == "" then err = "git log failed" end
          notify(err, vim.log.levels.ERROR)
          return
        end

        local out = (res.stdout or ""):gsub("%s+$", "")
        if out == "" then
          notify("No history found for this line", vim.log.levels.INFO)
          return
        end

        local lines = vim.split(out, "\n", { plain = true })
        open_history_window(string.format("%s:%d", rel, line1), lines)
      end)
    end)

    inflight[bufnr] = handle
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader>gl", function()
    line_history()
  end, { desc = "Git line history", silent = true })
end

return M
