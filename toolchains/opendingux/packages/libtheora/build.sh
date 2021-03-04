#! /bin/sh

# Stick with toolchain version
LIBTHEORA_VERSION=1.0
LIBTHEORA_SHA256=3ae9df56e8fc75ffe26e63a13cae2ce79d079416175fb0baffe0e2de8dc91a6d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libtheora "http://downloads.xiph.org/releases/theora/libtheora-${LIBTHEORA_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${LIBTHEORA_SHA256}"

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
