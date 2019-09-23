m4_divert(`-1')

m4_define(`fatal_error',
  `m4_errprint(m4_ifdef(`m4___program__', `m4___program__', ``m4'')'m4_dnl
`:m4_ifelse(m4___line__, `0', `',
    `m4___file__:m4___line__:')` fatal error: $*
')m4_m4exit(`1')')

m4_dnl foreachq(x, `item_1, item_2, ..., item_n', stmt)
m4_dnl   quoted list, alternate improved version
m4_define(`m4_foreachq', `m4_ifelse(`$2', `', `',
  `m4_pushdef(`$1')_$0(`$1', `$3', `', $2)m4_popdef(`$1')')')
m4_define(`_m4_foreachq', `m4_ifelse(`$#', `3', `',
  `m4_define(`$1', `$4')$2`'$0(`$1', `$2',
    m4_shift(m4_shift(m4_shift($@))))')')

m4_define(`environmentalize', `m4_translit(`$*', `a-z+-', `A-ZX_')')

m4_divert`'m4_dnl
