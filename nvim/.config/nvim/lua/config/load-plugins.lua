-- lua/config/load-plugins.lua
local M = {}

local function gh(repo)
  return "https://github.com/" .. repo
end

local function postProcessingAfterInstallation(ev)
  if not ev.data or not ev.data.kind or not ev.data.spec or not ev.data.spec.name then
    return
  end
  local kind = ev.data.kind
  local name = ev.data.spec.name
  local path = ev.data.path
  if (kind == "install" or kind == "update") then
    if name == "fzf" then
      vim.system({ "sh", "-c", "./install --all" }, { cwd = path })
    end

    if name == "cornelis" then
      vim.system({ "stack", "build" }, { cwd = path })
    end
  end
end

function M.setup()
  -- Run post-install/update hooks
  local packchanged_group = vim.api.nvim_create_augroup("PackChangedPostInstall", { clear = true })
  vim.api.nvim_create_autocmd("PackChanged", {
    group = packchanged_group,
    callback = postProcessingAfterInstallation,
  })

  -- Global plugins
  vim.pack.add({
    gh("rktjmp/lush.nvim"), -- required by jellybeans-nvim
    gh("metalelf0/jellybeans-nvim"),

    { src = gh("junegunn/fzf"), name = "fzf" },
    gh("junegunn/fzf.vim"),
    gh("nvim-lua/plenary.nvim"),
    gh("axelf4/vim-strip-trailing-whitespace"),
    gh("windwp/nvim-autopairs"),
    gh("tpope/vim-projectionist"),

    gh("j-hui/fidget.nvim"), -- LSP UI

    -- completion/snippets
    gh("hrsh7th/nvim-cmp"),
    gh("hrsh7th/cmp-nvim-lsp"),
    gh("L3MON4D3/LuaSnip"),
    gh("saadparwaiz1/cmp_luasnip"),

  }, { load = true })

  -- Optional plugins
  vim.pack.add({
    { src = gh("scalameta/nvim-metals"), name = "nvim-metals" },
    { src = gh("Mrcjkb/haskell-tools.nvim"), name = "haskell-tools.nvim" },
    { src = gh("kana/vim-textobj-user"), name = "vim-textobj-user" }, -- required by cornelis
    { src = gh("neovimhaskell/nvim-hs.vim"), name = "nvim-hs.vim" }, -- required by cornelis
    { src = gh("agda/cornelis"), name = "cornelis" },
  }, { load = false })

  local group = vim.api.nvim_create_augroup("LazyPlugins", { clear = true })

  -- metals
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = {"scala", "sbt"},
    callback = function()
      vim.cmd("packadd nvim-metals")
    end,
  })

  -- haskell
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "haskell", "lhaskell", "cabal", "stack" },
    callback = function()
      vim.cmd("packadd haskell-tools.nvim")
    end,
  })

  -- Agda
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "agda",
    callback = function()
      vim.cmd("packadd vim-textobj-user")
      vim.cmd("packadd nvim-hs.vim")
      vim.cmd("packadd cornelis")
    end,
  })

end

return M
