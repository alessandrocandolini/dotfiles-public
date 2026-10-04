-- cleveref labels are identifiers, not prose (including starred forms).
vim.cmd([=[
  syntax region texRefZone matchgroup=texStatement start='\\[cC]ref\*\=\s*{' end='}' contains=@NoSpell
]=])

-- biblatex citation keys are identifiers; optional citation notes are prose.
vim.cmd([=[
  syntax match texRefZone '\\[aA]utocite\>\*\=' nextgroup=texAutoCiteNote,texAutoCiteKey skipwhite skipnl
  syntax region texAutoCiteNote contained matchgroup=texDelimiter start='\[' end=']' contains=@texMatchGroup,@Spell nextgroup=texAutoCiteNote,texAutoCiteKey skipwhite skipnl
  syntax region texAutoCiteKey contained matchgroup=texDelimiter start='{' end='}' contains=@NoSpell
  highlight default link texAutoCiteKey texRefZone

  " Asymptote file paths and options are not prose.
  syntax match texInputFile '\\asy\%(include\|import\)\>\s*\%(\[[^]]*\]\s*\)\?{[^}]*}' contains=texStatement,texInputCurlies,texInputFileOpt,@NoSpell
]=])

-- breqn display maths, including dmath*, uses the built-in maths rules.
if vim.fn.exists("*TexNewMathZone") == 1 then
  vim.fn.TexNewMathZone("Dmath", "dmath", 1)
end
