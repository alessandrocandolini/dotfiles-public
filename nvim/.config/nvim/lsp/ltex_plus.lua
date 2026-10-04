return {
  cmd = { "ltex-ls-plus" },
  filetypes = { "tex", "plaintex", "markdown" },
  root_markers = { ".git" },
  get_language_id = function(_, filetype)
    if filetype == "tex" or filetype == "plaintex" then
      return "latex"
    end
    return filetype
  end,
  settings = {
    ltex = {
      enabled = { "latex", "markdown" },
      language = "en-GB",
      -- Ignored breqn equations leave whitespace before their trailing comma,
      -- causing false positives spanning the whole equation. This also disables
      -- genuine comma-spacing warnings; grammar and spelling rules stay active.
      disabledRules = {
        ["en-GB"] = { "COMMA_PARENTHESIS_WHITESPACE" },
      },
      latex = {
        commands = {
          ["\\asyinclude{}"] = "ignore",
          ["\\asyinclude[]{}"] = "ignore",
          ["\\asyimport{}"] = "ignore",
          ["\\asyimport[]{}"] = "ignore",
        },
        environments = {
          dmath = "ignore",
          ["dmath*"] = "ignore",
        },
      },
    },
  },
}
