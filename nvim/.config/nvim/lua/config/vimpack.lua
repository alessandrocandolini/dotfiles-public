local M = {}

local function gh(repo)
  return "https://github.com/" .. repo
end

local function runPostInstallationHook(cmd, opts)
  opts = opts or {}
  local cwd = opts.cwd

  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      local cmd_str = table.concat(cmd, " ")
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
end

local function postProcessingAfterInstallation(ev)
  if not ev.data or not ev.data.kind or not ev.data.spec or not ev.data.spec.name then
    return
  end
  local kind = ev.data.kind
  local name = ev.data.spec.name
  local path = ev.data.path
  if kind == "install" or kind == "update" then
    if name == "cornelis" then
      runPostInstallationHook({ "stack", "build" }, { cwd = path })
    end
  end
end

function M.setup()
  local packchanged_group = vim.api.nvim_create_augroup("PackChangedPostInstall", { clear = true })
  vim.api.nvim_create_autocmd("PackChanged", {
    group = packchanged_group,
    callback = postProcessingAfterInstallation,
  })

  -- Global plugins
  vim.pack.add({
    gh("wtfox/jellybeans.nvim"),

    gh("ibhagwan/fzf-lua"),
    gh("nvim-lua/plenary.nvim"),
    gh("axelf4/vim-strip-trailing-whitespace"),
    gh("windwp/nvim-autopairs"),
    gh("tpope/vim-projectionist"),
    gh("j-hui/fidget.nvim"), -- LSP loader indicator
    gh("stevearc/oil.nvim"),

    -- completion/snippets
    gh("hrsh7th/nvim-cmp"),
    gh("hrsh7th/cmp-nvim-lsp"),
    gh("L3MON4D3/LuaSnip"),
    gh("saadparwaiz1/cmp_luasnip"),

  }, { load = true })

  -- Optional plugins (they are loaded on specific buffers in ftplugin)
  vim.pack.add({
    { src = gh("scalameta/nvim-metals"), name = "nvim-metals" },
    { src = gh("Mrcjkb/haskell-tools.nvim"), name = "haskell-tools.nvim" },
    { src = gh("kana/vim-textobj-user"), name = "vim-textobj-user" }, -- required by cornelis
    { src = gh("neovimhaskell/nvim-hs.vim"), name = "nvim-hs.vim" }, -- required by cornelis
    { src = gh("agda/cornelis"), name = "cornelis" },
  }, { load = false })

end

return M
