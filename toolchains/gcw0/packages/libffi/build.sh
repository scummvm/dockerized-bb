#! /bin/sh

# Stick with toolchain version
LIBFFI_VERSION=3.0.13
LIBFFI_SHA256=1dddde1400c3bcb7749d398071af88c3e4754058d2d4c0b3696c2f82dc5cf11c

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libffi "https://sourceware.org/pub/libffi/libffi-${LIBFFI_VERSION}.tar.gz" 'tar xzf' "sha256:${LIBFFI_SHA256}"

do_configure_shared --disable-builddir
do_make
# Install only includes and library (no man pages, nor info)
do_make -C include install
do_make install-pkgconfigDATA install-toolexeclibLTLIBRARIES

#mv "${PREFIX}"/lib/libffi-${LIBFFI_VERSION}/include/*.h ${PREFIX}/include/
#sed -i '/^includedir.*/d' -e '/^Cflags:.*/d' ${PREFIX}/lib/pkgconfig/libffi.pc
#rm -rf "${PREFIX}"/usr/lib/libffi-*

do_clean_bdir
