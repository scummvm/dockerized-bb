#! /bin/sh

# Stick with toolchain versions
LIBPTHREAD_STUBS_VERSION=0.3
LIBPTHREAD_STUBS_SHA256=35b6d54e3cc6f3ba28061da81af64b9a92b7b757319098172488a660e3d87299
LIBDRM_VERSION=2.4.54
LIBDRM_SHA256=d94001ebfbe80e1523d1228ee2df57294698d1c734fad9ccf53efde8932fe4e9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libpthread-stubs "http://xcb.freedesktop.org/dist/libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.bz2" 'tar xjf' "sha256:${LIBPTHREAD_STUBS_SHA256}"

do_configure_shared

do_make
do_make install

cd ..

do_http_fetch libdrm "http://dri.freedesktop.org/libdrm/libdrm-${LIBDRM_VERSION}.tar.bz2" 'tar xjf' "sha256:${LIBDRM_SHA256}"

do_configure_shared --disable-manpages \
	--disable-cairo-tests \
	--disable-intel \
	--disable-radeon \
	--disable-nouveau \
	--disable-vmwgfx \
	--disable-omap-experimental-api \
	--disable-exynos-experimental-api \
	--disable-freedreno-experimental-api

do_make
do_make install

do_clean_bdir
