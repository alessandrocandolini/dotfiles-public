local M = {}

local function notify(message)
  vim.notify("Hoogle: " .. message, vim.log.levels.INFO)
end

local function documentation(item)
  local entities = { lt = "<", gt = ">", amp = "&", quot = '"', apos = "'", nbsp = " " }
  local docs = (item.docs or "")
    :gsub("<br%s*/?>", "\n"):gsub("<li>", "\n- ")
    :gsub("</([%w]+)>", function(tag)
      return ({ p = true, pre = true, li = true, h4 = true })[tag] and "\n" or ""
    end)
    :gsub("<[^>]+>", "")
    :gsub("&(#?[%w]+);", function(entity)
      local code = tonumber(entity:match("^#(%d+)$")) or tonumber(entity:match("^#x(%x+)$") or "", 16)
      return entities[entity] or (code and vim.fn.nr2char(code)) or ("&" .. entity .. ";")
    end)
  return table.concat({ item.item, (item.package or {}).name or "", (item.module or {}).name or "",
    "", vim.trim(docs) ~= "" and vim.trim(docs) or "No documentation available." }, "\n")
end

function M.search(initial_query)
  if vim.fn.executable("hoogle") ~= 1 then return notify("hoogle is not on PATH") end
  local items, process, generation = {}, nil, 0
  local function cancel()
    generation = generation + 1
    if process then process:kill(15); process = nil end
  end
  require("fzf-lua").fzf_live(function(args)
    return function(cb)
      cancel()
      local request = generation
      local query = vim.trim(args[1] or "")
      if query == "" then return cb(nil) end
      process = vim.system({ "hoogle", "search", "--json", "--count=50", query },
        { text = true, timeout = 5000 }, vim.schedule_wrap(function(output)
        if request ~= generation then return cb(nil) end
        process = nil
        local stdout = vim.trim(output.stdout or "")
        local ok, results = pcall(vim.json.decode, stdout)
        if output.code ~= 0 or not ok or type(results) ~= "table" then
          local message = vim.trim(output.stderr or "")
          cb("Hoogle: " .. (message ~= "" and message or stdout ~= "" and stdout or "search failed"):gsub("%s+", " "))
          return cb(nil)
        end
        for _, item in ipairs(results) do
          local entry = string.format("%s  %s", (item.module or {}).name or "", item.item or "")
          items[entry] = item
          cb(entry)
        end
        if #results == 0 then cb("Hoogle: No results found") end
        cb(nil)
      end))
    end
  end, {
    prompt = "Hoogle> ",
    query = initial_query or "",
    multiprocess = false,
    query_delay = 200,
    previewer = false,
    preview = function(selected)
      local item = items[selected[1]]
      return item and documentation(item) or ""
    end,
    winopts = { preview = { wrap = true }, on_close = cancel },
    fzf_opts = { ["--header"] = "Type a name or signature | Enter: copy name | Ctrl-/: docs",
      ["--no-sort"] = true, ["--no-multi"] = true },
    actions = {
      ["enter"] = function(selected)
        local item = items[selected[1]]
        local name = item and item.item:match("^(%S+)%s+::")
        if name then vim.fn.setreg('"', name) end
      end,
    },
  })
end

local original_hoogle
function M.connect_hover(ht)
  if original_hoogle then return end
  original_hoogle = ht.hoogle.hoogle_signature
  ht.hoogle.hoogle_signature = function(opts)
    if not (opts and opts.search_term) then return original_hoogle(opts) end
    -- Let the hover close before fzf takes focus.
    vim.schedule(function() M.search(opts.search_term) end)
  end
end

return M
