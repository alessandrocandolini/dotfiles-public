-- Setup comments
require('Comment').setup()
vim.keymap.set('n', '<leader>cc', 'gcc', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>cc', 'gc', { noremap = true, silent = true })

-- Completion options
vim.opt_global.completeopt = { "menu", "menuone", "noselect" }

-- Diagnostics Keybindings
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[c', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']c', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local buf_opts = { buffer = ev.buf, noremap = true, silent = true }

    -- Standard LSP keybindings
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, buf_opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, buf_opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, buf_opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, buf_opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, buf_opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, buf_opts)

    -- Code actions and renaming
    vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, buf_opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, buf_opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, buf_opts)  -- **Restored**

    -- Workspace folder management (Restored)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, buf_opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, buf_opts)
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, buf_opts)

    -- Type definition
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, buf_opts)

    -- Formatting (Restored)
    vim.keymap.set('n', '<leader>F', function()
      print("formatting...")
      vim.lsp.buf.format { async = true }
    end, buf_opts)
  end,
})

-- Autocompletion setup
local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },  -- Use LuaSnip instead of vsnip
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    -- if you remove snippets you need to remove this select
    ['<cr>'] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
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

-- Metals (scala)
local metals_config = require("metals").bare_config()

metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()
metals_config.on_attach = default_on_attach
metals_config.settings = {
  showImplicitArguments = true,
  serverVersion = "latest.snapshot",
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



