local M = {}

M.languages = {
  c = 'C',
  kotlin = 'Kotlin',
  python = 'Python',
  typescript = 'TypeScript',
  typescriptreact = 'TypeScript',
}

function M.enabled(path)
  return M.languages[vim.bo.filetype] ~= nil and not vim.fs.root(path, function(name)
    return name == 'cabal.project' or name == 'stack.yaml' or name:match('%.cabal$') ~= nil
  end)
end

function M.setup()
  vim.cmd([[
    function! GutentagsEnabled(path) abort
      return luaeval("require('config.tags').enabled(_A)", a:path)
    endfunction
  ]])
  vim.g.gutentags_init_user_func = 'GutentagsEnabled'
  vim.g.gutentags_modules = { 'ctags' }
  vim.g.gutentags_project_root = { '.root' }
  vim.g.gutentags_resolve_symlinks = 1
  vim.g.gutentags_file_list_command = 'rg --files --hidden -g !.git -g !tags'

  local languages = vim.fn.uniq(vim.fn.sort(vim.tbl_values(M.languages)))
  vim.g.gutentags_ctags_extra_args = {
    '--languages=' .. table.concat(languages, ','),
    '--map-TypeScript=+.tsx',
  }
end

return M
