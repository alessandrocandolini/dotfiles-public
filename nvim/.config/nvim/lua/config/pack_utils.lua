local M = {}

local function run_post_install(cmd, cwd)
  local cmd_str = table.concat(cmd, " ")

  if not vim.api.nvim_list_uis()[1] then
    vim.system(cmd, { cwd = cwd, text = true }, function(res)
      vim.schedule(function()
        local message, level
        if res.code == 0 then
          message = ("✅ Post installation hook %s succeeded"):format(cmd_str)
          level = vim.log.levels.INFO
        else
          message = string.format(
            "❌ Post installation hook %s failed\ncwd: %s\nexit: %s\n\nstdout:\n%s\n\nstderr:\n%s",
            cmd_str,
            cwd or "(nil)",
            tostring(res.code),
            res.stdout or "",
            res.stderr or ""
          )
          level = vim.log.levels.ERROR
        end
        vim.notify(message, level, { title = "vim.pack" })
      end)
    end)
    return
  end

  local out_file = vim.fn.tempname()
  local err_file = vim.fn.tempname()

  vim.notify(("▶ Post installation hook starting: %s"):format(cmd_str), vim.log.levels.INFO, { title = "vim.pack" })

  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("enew")

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("stopinsert")

  local script = string.format([[
set -e
out=%q
err=%q
"$@" 1> >(tee "$out") 2> >(tee "$err" >&2)
exit $?
]], out_file, err_file)

  local term_cmd = { "bash", "-lc", script, "_" }
  for _, a in ipairs(cmd) do
    term_cmd[#term_cmd + 1] = a
  end

  local function slurp_tail(path, max_lines)
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok or not lines then
      return ""
    end
    
    local total = #lines
    if max_lines and total > max_lines then
      local truncated = {}
      for i = total - max_lines + 1, total do
        table.insert(truncated, lines[i])
      end
      local header = string.format("... (showing last %d of %d lines) ...\n", max_lines, total)
      return header .. table.concat(truncated, "\n")
    end
    
    return table.concat(lines, "\n")
  end

  local function scroll_to_bottom()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local wins = vim.fn.win_findbuf(buf)
    if not wins or #wins == 0 then
      return
    end
    local last = vim.api.nvim_buf_line_count(buf)
    for _, w in ipairs(wins) do
      if vim.api.nvim_win_is_valid(w) then
        vim.api.nvim_win_set_cursor(w, { last, 0 })
      end
    end
  end

  local function on_output(_, data)
    if not data then
      return
    end
    vim.schedule(scroll_to_bottom)
  end

  vim.fn.termopen(term_cmd, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(_, code)
      vim.schedule(function()
        scroll_to_bottom()

        local message, level
        if code == 0 then
          message = ("✅ Post installation hook %s succeeded"):format(cmd_str)
          level = vim.log.levels.INFO
        else
          -- Only read temp files on failure, and truncate to last 50 lines
          local stdout = slurp_tail(out_file, 50)
          local stderr = slurp_tail(err_file, 50)
          
          message = string.format(
            "❌ Post installation hook %s failed\ncwd: %s\nexit: %s\n\nstdout:\n%s\n\nstderr:\n%s",
            cmd_str,
            cwd or "(nil)",
            tostring(code),
            stdout or "",
            stderr or ""
          )
          level = vim.log.levels.ERROR
        end

        -- Always clean up temp files
        pcall(vim.fn.delete, out_file)
        pcall(vim.fn.delete, err_file)

        vim.notify(message, level, { title = "vim.pack" })
      end)
    end,
  })

  vim.cmd("stopinsert")
  vim.schedule(scroll_to_bottom)
end

local function unpack_packchanged(ev)
  local d = ev and ev.data
  if not d then
    return nil
  end

  local kind = d.kind
  local spec = d.spec
  local name = spec and spec.name
  local path = d.path

  if not kind or not name or not path then
    return nil
  end

  return {
    kind = kind,
    name = name,
    path = path,
  }
end

function M.post_processing_hook(register)
  local rules = {}
  local builder = {}

  function builder:on(name_or_names, cmd, opts)
    opts = opts or {}
    local only = opts.only or { "install", "update" }

    local names
    if type(name_or_names) == "string" then
      names = { name_or_names }
    elseif type(name_or_names) == "table" then
      names = name_or_names
    else
      error("hook:on(...) expects name as string or list of strings")
    end

    table.insert(rules, {
      names = names,
      only = only,
      cmd = cmd,
    })
  end

  if register then
    register(builder)
  end

  return function(ev)
    local info = unpack_packchanged(ev)
    if not info then
      return
    end

    local kind, name, path = info.kind, info.name, info.path

    for _, r in ipairs(rules) do
      local ok_kind = false
      for _, k in ipairs(r.only) do
        if k == kind then
          ok_kind = true
          break
        end
      end
      if not ok_kind then
        goto continue
      end

      local ok_name = false
      for _, n in ipairs(r.names) do
        if n == name then
          ok_name = true
          break
        end
      end
      if not ok_name then
        goto continue
      end

      run_post_install(r.cmd, path)

      ::continue::
    end
  end
end

function M.gh(repo)
  return "https://github.com/" .. repo
end

return M
