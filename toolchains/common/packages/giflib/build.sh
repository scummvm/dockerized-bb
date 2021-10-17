#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch giflib

# -Wno-format-truncation is a recent addition to GCC remove it as we don't care about the warning
sed -i -e 's/-Wno-format-truncation //' Makefile

do_make libgif.a OFLAGS="${CPPFLAGS} ${CFLAGS} ${LDFLAGS}"

do_make install-include PREFIX=${PREFIX}
install -m 644 libgif.a "${LIBDIR:-${PKG_CONFIG_LIBDIR:-${PREFIX}/lib/pkgconfig}/..}/libgif.a"

do_clean_bdir
