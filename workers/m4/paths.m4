m4_divert(`-1')

m4_define(`def_binaries', `m4_foreachq(`binary', `$2',`environmentalize(binary)=`$1'binary ')')

m4_define(`def_aclocal', `ACLOCAL_PATH=`$1'/share/aclocal')
m4_define(`def_pkg_config', `PKG_CONFIG_LIBDIR=`$1'/lib/pkgconfig')

m4_divert`'m4_dnl
