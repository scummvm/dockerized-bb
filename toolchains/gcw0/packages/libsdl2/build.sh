#! /bin/sh

# Original toolchain used a fork by P. Cercueil which is not available anymore
# Use base commit from official git repository and apply GCW0 patches on it
SDL_VERSION=ec5f6ad5955c413c0fb42dc2c6d4ecaaff49db23

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL "https://github.com/libsdl-org/SDL/archive/${SDL_VERSION}.tar.gz" 'tar xzf'

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
