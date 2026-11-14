local M = {}

local function config(cmp)
  local function jump(direction, fallback)
    if cmp.visible() then
      local select = direction == 1 and cmp.select_next_item or cmp.select_prev_item
      select({ behavior = cmp.SelectBehavior.Select })
    elseif vim.snippet.active({ direction = direction }) then
      vim.snippet.jump(direction)
    else
      fallback()
    end
  end

  return {
    -- Keep Enter as a newline until a completion is explicitly selected.
    preselect = cmp.PreselectMode.None,
    snippet = { expand = function(args) vim.snippet.expand(args.body) end },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<Nul>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Insert }),
      ['<Tab>'] = cmp.mapping(function(fallback) jump(1, fallback) end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback) jump(-1, fallback) end, { 'i', 's' }),
      ['<Esc>'] = cmp.mapping(function(fallback)
        local keep_insert = cmp.visible() and vim.snippet.active()
        cmp.abort()
        if not keep_insert then fallback() end
      end),
    }),
    sources = {
      { name = 'haskell_snippets' },
      { name = 'nvim_lsp' },
    },
  }
end

function M.setup()
  local cmp = require('cmp')
  vim.lsp.config('*', { capabilities = require('cmp_nvim_lsp').default_capabilities({
    preselectSupport = false,
    commitCharactersSupport = false,
  }) })
  cmp.register_source('haskell_snippets', require('config.haskell_snippets'))

  cmp.setup(config(cmp))

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('CompletionSources', { clear = true }),
    callback = require('cmp_nvim_lsp')._on_insert_enter,
  })
end

return M
