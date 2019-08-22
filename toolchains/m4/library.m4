m4_define(`fatal_error',
  `m4_errprint(m4_ifdef(`m4___program__', `m4___program__', ``m4'')'m4_dnl
`:m4_ifelse(m4___line__, `0', `',
    `m4___file__:m4___line__:')` fatal error: $*
')m4_m4exit(`1')')m4_dnl
