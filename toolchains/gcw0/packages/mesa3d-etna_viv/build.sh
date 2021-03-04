#! /bin/sh

# Stick with toolchain version
MESA3D_ETNA_VIV_VERSION=4bd08c55bee04a2fd09edbf5f23bbf808b9cc1c1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch mesa "https://github.com/laanwj/mesa/archive/${MESA3D_ETNA_VIV_VERSION}.tar.gz" 'tar xzf'

NOCONFIGURE=1 ./autogen.sh

export ETNA_LIBS="${PREFIX}/lib/libetnaviv.a"

do_configure_shared \
	--disable-glx \
	--enable-dri --with-dri-drivers= \
	--with-gallium-drivers=swrast,etna \
	--disable-static --enable-shared \
	--enable-egl --with-egl-platforms=fbdev \
	--enable-gallium-egl \
	--enable-gles1 --enable-gles2 \

do_make

do_make install

do_clean_bdir
