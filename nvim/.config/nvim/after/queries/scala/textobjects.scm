; extends

; The Scala grammar includes trailing newlines in indented bodies. Keep cif
; from consuming the separator before the next definition.
((function_definition
  body: [
    (indented_block)
    (expression)
    (indented_cases)
    (block)
  ] @function.inner) @function.outer
  (#trim! @function.inner 1 1 1 1)
  (#trim! @function.outer 1 1 1 1))
