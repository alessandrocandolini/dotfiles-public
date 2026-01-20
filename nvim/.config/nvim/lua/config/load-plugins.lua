-- lua/config/plugins.lua
local M = {}

local function gh(repo)
  return "https://github.com/" .. repo
end

local function pack_hooks(ev)
  local spec = ev.data.spec
  local name, kind, path = spec.name, ev.data.kind, ev.data.path

  -- fzf: run install script after install/update
  if name == "fzf" and (kind == "install" or kind == "update") then
    vim.system({ "sh", "-c", "./install --all" }, { cwd = path })
  end

  -- cornelis: build via stack after install/update
  if name == "cornelis" and (kind == "install" or kind == "update") then
    vim.system({ "stack", "build" }, { cwd = path })
  end
end

function M.setup()
  -- Run post-install/update hooks
  vim.api.nvim_create_autocmd("PackChanged", { callback = pack_hooks })

  -- Always-on plugins
  vim.pack.add({
    gh("rktjmp/lush.nvim"), -- required by jellybeans-nvim
    gh("metalelf0/jellybeans-nvim"),

    gh("axelf4/vim-strip-trailing-whitespace"),
    gh("windwp/nvim-autopairs"),
    gh("tpope/vim-projectionist"),

    gh("nvim-lua/plenary.nvim"),

    -- fzf (needs post-install hook)
    { src = gh("junegunn/fzf"), name = "fzf" },
    gh("junegunn/fzf.vim"),

    -- LSPs
    gh("j-hui/fidget.nvim"),
    gh("scalameta/nvim-metals"),

    -- completion/snippets
    gh("hrsh7th/nvim-cmp"),
    gh("hrsh7th/cmp-nvim-lsp"),
    gh("L3MON4D3/LuaSnip"),
    gh("saadparwaiz1/cmp_luasnip"),

    -- Agda
    gh("kana/vim-textobj-user"),
    gh("neovimhaskell/nvim-hs.vim"),
    { src = gh("agda/cornelis"), name = "cornelis" }, -- stack build hook above
  })

  -- Lazy-loaded plugins (installed as opt, not loaded on startup)
  vim.pack.add({
    { src = gh("Mrcjkb/haskell-tools.nvim"), name = "haskell-tools.nvim", opt = true },
  })

  -- Lazy load haskell-tools.nvim on Haskell filetype
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "haskell",
    callback = function()
      -- Load the plugin if not already loaded
      vim.pack.load("haskell-tools.nvim")
    end,
  })

end

return M
