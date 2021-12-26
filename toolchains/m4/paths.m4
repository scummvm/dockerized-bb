m4_divert(`-1')

m4_define(`def_binaries', `m4_foreachq(`binary', `$2',`environmentalize(binary)=`$1'binary ')')

m4_define(`def_aclocal', `ACLOCAL_PATH="`$1'/share/aclocal"')
m4_define(`def_pkg_config', `PKG_CONFIG_LIBDIR="`$1'/lib/pkgconfig:`$1'/share/pkgconfig"')

m4_define(`crossgen', ``COPY --from=helpers /lib-helpers/meson-crossgen lib-helpers/meson-crossgen''
RUN $4 ``lib-helpers/meson-crossgen'' -o /usr/local/share/meson/cross/cross.ini --system=$1 --cpu=$2 $3)

m4_divert`'m4_dnl
