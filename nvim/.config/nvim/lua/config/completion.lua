local M = {}
local sources = { 'haskell_snippets', 'lsp' }

local function complete_manually(cmp)
  cmp.hide()
  return cmp.show({ providers = sources })
end

function M.setup()
  vim.opt.autocomplete = false
  vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })

  vim.keymap.set('i', '<CR>', function()
    local cmp = require('blink.cmp')
    if cmp.is_menu_visible() and cmp.get_selected_item() then
      return vim.keycode("<Cmd>lua require('blink.cmp').accept()<CR>")
    end
    return require('nvim-autopairs').autopairs_cr()
  end, { expr = true, replace_keycodes = false, silent = true, desc = 'Accept selected completion or insert newline' })

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = vim.api.nvim_create_augroup('CompletionSetup', { clear = true }),
    once = true,
    callback = function()
      require('blink.cmp').setup({
        keymap = {
          preset = 'none',
          ['<CR>'] = false,
          ['<C-e>'] = { 'cancel', 'fallback' },
          ['<C-y>'] = { 'accept', 'fallback' },
          ['<C-n>'] = { 'select_next', 'fallback' },
          ['<C-p>'] = { 'select_prev', 'fallback' },
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<C-Space>'] = { complete_manually },
          ['<Nul>'] = { complete_manually },
          ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
          ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
          ['<Esc>'] = {
            function(cmp)
              local keep_insert = vim.snippet.active() and cmp.is_menu_visible()
              cmp.cancel()
              return keep_insert
            end,
            'fallback',
          },
        },
        completion = {
          menu = { draw = { columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } } } },
          trigger = {
            prefetch_on_insert = false,
            show_on_insert = false,
            show_on_insert_on_trigger_character = false,
            show_on_backspace_after_insert_enter = false,
            show_on_accept_on_trigger_character = false,
          },
          list = { selection = { preselect = false, auto_insert = false } },
          accept = { auto_brackets = { enabled = false } },
          documentation = { auto_show = true },
        },
        sources = {
          default = sources,
          providers = {
            haskell_snippets = {
              name = 'Haskell snippets',
              module = 'config.haskell_snippets',
              enabled = function() return vim.bo.filetype == 'haskell' end,
              score_offset = 3,
            },
            lsp = { async = true, fallbacks = {} },
          },
        },
        fuzzy = { implementation = 'lua' },
        snippets = { preset = 'default' },
        signature = { enabled = true },
        cmdline = { enabled = false },
        term = { enabled = false },
      })
    end,
  })
end

return M
