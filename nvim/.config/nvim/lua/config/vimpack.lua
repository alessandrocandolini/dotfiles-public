local M = {}

local function gh(repo, optional)
  return { src = "https://github.com/" .. repo, name = repo:match("([^/]+)$"), optional = optional }
end

M.specs = {
  gh("wtfox/jellybeans.nvim"),
  gh("ibhagwan/fzf-lua"),
  gh("nvim-lua/plenary.nvim"),
  gh("axelf4/vim-strip-trailing-whitespace"),
  gh("windwp/nvim-autopairs"),
  gh("tpope/vim-projectionist"),
  gh("j-hui/fidget.nvim"),
  gh("stevearc/oil.nvim"),
  gh("LnL7/vim-nix"),
  gh("scalameta/nvim-metals", true),
  gh("Mrcjkb/haskell-tools.nvim", true),
  gh("kana/vim-textobj-user", true), -- required by cornelis
  gh("neovimhaskell/nvim-hs.vim", true), -- required by cornelis
  gh("agda/cornelis", true),
}

M.build_hooks = { cornelis = { "stack", "build" } }

local excluded = vim.split(vim.env.NVIM_PACK_EXCLUDE or "", ",", { trimempty = true })
M.specs = vim.tbl_filter(function(spec)
  return not vim.tbl_contains(excluded, spec.name)
end, M.specs)

local function read(path)
  local file = assert(io.open(path, "rb"), "Cannot read " .. path)
  local contents = file:read("*a")
  file:close()
  return contents
end

local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "wb"))
  assert(file:write(contents))
  assert(file:close())
end

local function encode(value)
  return vim.json.encode(value, { indent = "  ", sort_keys = true }) .. "\n"
end

local function plugin_path(name)
  return vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name
end

local function receipt_path()
  return vim.fn.stdpath("state") .. "/nvim-pack-sync"
end

local function fingerprint(lock)
  return vim.fn.sha256(lock .. encode(M.specs) .. encode(M.build_hooks) .. vim.fn.stdpath("data"))
end

local function command(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  assert(result.code == 0 and result.signal == 0, string.format(
    "%s failed (exit %s, signal %s)\ncwd: %s\n%s\n%s",
    table.concat(cmd, " "), result.code, result.signal, cwd, result.stdout or "", result.stderr or ""
  ))
  return vim.trim(result.stdout or "")
end

-- Startup only loads prepared packages. It never invokes vim.pack's installation
-- or lockfile-repair machinery, and does not need Git or network access.
function M.setup()
  local lock = read(vim.fn.stdpath("config") .. "/nvim-pack-lock.json")
  local ok, receipt = pcall(read, receipt_path())
  assert(ok and receipt == fingerprint(lock), "Neovim packages need syncing: run make nvim-sync")
  local plugins = vim.json.decode(lock).plugins
  for _, spec in ipairs(M.specs) do
    local head_ok, head = pcall(read, plugin_path(spec.name) .. "/.git/HEAD")
    assert(head_ok and vim.trim(head) == plugins[spec.name].rev,
      spec.name .. " differs from the lockfile: run make nvim-sync")
    vim.cmd.packadd({ spec.name, bang = spec.optional or vim.v.vim_did_init == 0 })
  end
end

-- Run in a fresh headless process, before any vim.pack calls.
function M.manage(mode, lock_path)
  assert(mode == "sync" or mode == "update", "Expected sync or update")
  lock_path = vim.uv.fs_realpath(lock_path) or lock_path
  local original = read(lock_path)
  local desired = vim.json.decode(original)
  local names, specs, seed = {}, {}, { plugins = {} }
  for _, spec in ipairs(M.specs) do
    local entry = desired.plugins[spec.name]
    if mode == "sync" then
      assert(entry and entry.src == spec.src and type(entry.rev) == "string",
        spec.name .. " is missing or differs from the lockfile: run make nvim-update first")
    end
    names[#names + 1] = spec.name
    specs[#specs + 1] = { src = spec.src, name = spec.name, version = spec.version }
    seed.plugins[spec.name] = entry
  end

  local temp = vim.fn.tempname()
  vim.fn.mkdir(temp, "p")
  local original_lock_option = vim.o.packlockfile
  local env = {}
  for _, key in ipairs({ "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME" }) do
    env[key] = vim.env[key]
  end
  local original_packpath = vim.o.packpath
  local ok, err = xpcall(function()
    if mode == "update" then
      -- Resolve updates without touching this machine's installed plugins or builds.
      vim.env.XDG_DATA_HOME = temp .. "/data"
      vim.env.XDG_STATE_HOME = temp .. "/state"
      vim.env.XDG_CACHE_HOME = temp .. "/cache"
      vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")
    else
      -- A failed sync must never leave a previous success receipt in place.
      vim.fn.delete(receipt_path())
    end
    local scratch_lock = temp .. "/nvim-pack-lock.json"
    write(scratch_lock, encode(seed))
    vim.o.packlockfile = scratch_lock
    vim.pack.add(specs, { load = false, confirm = false })

    local targets = seed.plugins
    if mode == "update" then
      -- A failed fetch leaves rev_to unset. Check it explicitly instead of parsing logs.
      targets = {}
      for _, plugin in ipairs(vim.pack.get(names, { offline = false })) do
        assert(plugin.rev_to, "Could not resolve update for " .. plugin.spec.name)
        targets[plugin.spec.name] = { rev = plugin.rev_to }
      end
    end
    vim.pack.update(names, { force = true, target = mode == "sync" and "lockfile" or "version",
      offline = mode == "update" })
    for _, name in ipairs(names) do
      local actual = command({ "git", "rev-parse", "HEAD" }, plugin_path(name))
      assert(actual == targets[name].rev, name .. " did not reach the requested revision")
    end

    if mode == "sync" then
      -- Run even on unchanged checkouts: builds are incremental, and failed builds
      -- must be retried rather than skipped because no PackChanged event occurred.
      for _, name in ipairs(names) do
        if M.build_hooks[name] then
          print("Building " .. name)
          command(M.build_hooks[name], plugin_path(name))
        end
      end
      assert(read(lock_path) == original, "Lockfile changed during sync; run make nvim-sync again")
      write(receipt_path(), fingerprint(original))
    else
      local resolved = vim.json.decode(read(scratch_lock))
      local output = { plugins = {} }
      for _, name in ipairs(names) do
        output.plugins[name] = assert(resolved.plugins[name])
      end
      -- Publish only a fully resolved update, preserving a stowed lockfile symlink.
      assert(read(lock_path) == original, "Lockfile changed while resolving updates")
      write(lock_path .. ".tmp", encode(output))
      assert(vim.uv.fs_rename(lock_path .. ".tmp", lock_path))
    end
  end, debug.traceback)
  vim.o.packlockfile = original_lock_option
  vim.o.packpath = original_packpath
  if mode == "update" then
    for _, key in ipairs({ "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME" }) do
      vim.env[key] = env[key]
    end
  end
  vim.fn.delete(temp, "rf")
  if not ok then error(err, 0) end
  print(mode == "sync" and "Neovim packages synced successfully" or "Neovim lockfile updated; run make nvim-sync to apply")
end

return M
