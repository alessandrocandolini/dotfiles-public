--https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
--https://github.com/scalameta/nvim-metals/discussions/39


require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

vim.opt_global.completeopt = { "menuone", "noinsert", "noselect" }

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[c', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']c', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
-- ADVANTAGE: no mappings for other files
-- DOWNSIDE: you need to pass the function to every new LSP
local default_on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>sh', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', 'gds', vim.lsp.buf.document_symbol, bufopts)

  vim.keymap.set('n', 'gws', vim.lsp.buf.workspace_symbol, bufopts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<leader>h', function()
    print(vim.inspect(vim.lsp.buf_get_clients()))
  end, bufopts)
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, bufopts)

end

----------------------------------
-- Autocompletion
----------------------------------

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" }
  },
  mapping = cmp.mapping.preset.insert({
    --["<CR>"] = cmp.mapping.confirm({ select = false }),
    -- I use tabs... some say you should stick to ins-completion but this is just here as an example
    ["<Tab>"] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ["<S-Tab>"] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
  })
})

----------------------------------
-- LSP Setup
----------------------------------
-- Haskell language server
--require'lspconfig'.hls.setup{
  --on_attach = default_on_attach,
  --capabilities = capabilities,
  --settings = {
      --haskell = {
         --hlintOn = true,
         --formattingProvider = "ormolu"
      --}
  --}
--}

local ht = require('haskell-tools')

ht.setup {
  tools = { -- haskell-tools options
    codeLens = {
      autoRefresh = true,
    },
    hoogle = {
      -- 'auto': Choose a mode automatically, based on what is available.
      -- 'telescope-local': Force use of a local installation.
      -- 'telescope-web': The online version (depends on curl).
      -- 'browser': Open hoogle search in the default browser.
      --mode = 'telescope-local',
      mode = 'auto',
    },
  },
  hls = {
    on_attach = function(client, bufnr)
      local local_opts = vim.tbl_extend('keep', opts, { buffer = bufnr, })
      vim.keymap.set('n', '<leader>ca', vim.lsp.codelens.run, local_opts)
      vim.keymap.set('n', '<leader>hs', ht.hoogle.hoogle_signature, local_opts)
      default_on_attach(client, bufnr)
    end,
    haskell = {
      formattingProvider = 'ormolu',
      checkProject = false,
      plugin = {
       class = { -- missing class methods
        codeLensOn = true,
       },
       importLens = { -- make import lists fully explicit
         codeLensOn = true,
       },
       refineImports = { -- refine imports
         codeLensOn = true,
       },
       tactics = { -- wingman
         codeLensOn = false,
       },
       moduleName = { -- fix module names
         globalOn = true,
       },
       eval = { -- evaluate code snippets
         globalOn = false,
       },
       ['ghcide-type-lenses'] = { -- show/add missing type signatures
         globalOn = true,
       },
     },
    }
  },
}

-- Metals (scala)
local metals_config = require("metals").bare_config()

metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()
metals_config.on_attach = default_on_attach
metals_config.settings = {
  showImplicitArguments = true,
  excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
}


-- Autocmd that will actually be in charging of starting the whole thing
local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  -- NOTE: You may or may not want java included here. You will need it if you
  -- want basic Java support but it may also conflict if you are using
  -- something like nvim-jdtls which also works on a java filetype autocmd.
  pattern = { "scala", "sbt", "java" },
  callback = function()
    require("metals").initialize_or_attach(metals_config)
  end,
  group = nvim_metals_group,
})



