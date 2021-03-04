#! /bin/sh

# Stick with toolchain version
LIBTHEORA_VERSION=1.1.1
LIBTHEORA_SHA256=f36da409947aa2b3dcc6af0a8c2e3144bc19db2ed547d64e9171c59c66561c61

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libtheora "http://downloads.xiph.org/releases/theora/libtheora-${LIBTHEORA_VERSION}.tar.xz" \
	'tar xJf' "sha256:${LIBTHEORA_SHA256}"

# Avoid compiling and installing doc
sed -ie 's/^\(SUBDIRS.*\) doc/\1/' Makefile.am
autoreconf -fi -I m4

do_configure_shared \
	--disable-oggtest \
	--disable-vorbistest \
	--disable-sdltest \
	--disable-examples \
	--disable-spec
do_make
do_make install

do_clean_bdir
