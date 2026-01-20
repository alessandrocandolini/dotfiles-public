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
    gh("Mrcjkb/haskell-tools.nvim"),

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

end

return M
