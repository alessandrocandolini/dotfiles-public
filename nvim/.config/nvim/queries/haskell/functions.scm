; Full declarations only: do/let values must not shadow the enclosing function.
; Use a dedicated group so upstream equation-only captures cannot win.
((declarations
  [
    (function name: (_))
    (bind name: (_))
    (signature name: (_))
  ] @function.outer)
  (#haskell-definition! @function.outer))

((local_binds
  [
    (function name: (_))
    (bind name: (_))
    (signature name: (_))
  ] @function.outer) @_scope
  (#has-parent? @_scope "function" "bind")
  (#haskell-definition! @function.outer))

; Keep the equals sign and any guards outside the inner object.
(declarations
  [
    (function name: (_) match: (match expression: (_) @function.inner))
    (bind name: (_) match: (match expression: (_) @function.inner))
  ])

((local_binds
  [
    (function name: (_) match: (match expression: (_) @function.inner))
    (bind name: (_) match: (match expression: (_) @function.inner))
  ]) @_scope
  (#has-parent? @_scope "function" "bind"))
