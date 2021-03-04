#! /bin/sh

# Stick with toolchain version
SDL_VERSION=ec72e543fece666ce97b9f37f08518f40e2a2aea

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL2 "https://github.com/pcercuei/SDL2/archive/${SDL_VERSION}.tar.gz" 'tar xzf'

./autogen.sh

# The test fails because of cross-compilation
export ac_cv_func_memcmp_working=yes
do_configure_shared \
	--enable-rpath=no \
	--enable-video \
	--disable-video-x11 \
	--enable-video-opengles \
	--enable-video-fbdev \
	--enable-alsa --disable-oss

do_make

# No man pages
do_make install-bin install-hdrs install-lib install-data

do_clean_bdir
