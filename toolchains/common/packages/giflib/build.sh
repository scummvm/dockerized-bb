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

# Find the libc and install libgif next to it
if [ -z "${LIBDIR}" ]; then
	LIBDIR=$(dirname "$("$CC" -print-file-name="libc.a")")
	if [ "$LIBDIR" = . ]; then
		LIBDIR=
	fi
fi
if [ -z "${LIBDIR}" ]; then
	LIBDIR=${PREFIX}/lib
fi

install -m 644 libgif.a "${DESTDIR}${LIBDIR}/libgif.a"

do_clean_bdir
