local M = {}

local function config(cmp)
  local function select(direction)
    local move = direction == 1 and cmp.select_next_item or cmp.select_prev_item
    return move({ behavior = cmp.SelectBehavior.Select })
  end
  local function jump(direction, fallback)
    if cmp.visible() then
      select(direction)
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
    window = { completion = { border = 'none' } },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-n>'] = cmp.mapping(function() if not select(1) then cmp.complete() end end),
      ['<C-p>'] = cmp.mapping(function() if not select(-1) then cmp.complete() end end),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<Nul>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Insert }),
      ['<Tab>'] = cmp.mapping(function(fallback) jump(1, fallback) end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback) jump(-1, fallback) end, { 'i', 's' }),
      ['<Esc>'] = cmp.mapping(function(fallback)
        local keep_insert = cmp.visible() and vim.snippet.active()
        cmp.close()
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

  -- use private _on_insert_enter to register the completion engine on LspAttach.
  -- if the API gets removed, we can always remove this callback and just wait the LSP load before going in insert mode
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('CompletionSources', { clear = true }),
    callback = require('cmp_nvim_lsp')._on_insert_enter,
  })

end

return M
