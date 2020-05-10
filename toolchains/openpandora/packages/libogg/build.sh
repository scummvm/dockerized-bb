#! /bin/sh

# OpenPandora firmware uses libogg 1.1.4 (ABI 0.6.0) stick with it
LIBOGG_VERSION=1.1.4
LIBOGG_SHA256=9354c183fd88417c2860778b60b7896c9487d8f6e58b9fec3fdbf971142ce103

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libogg "http://downloads.xiph.org/releases/ogg/libogg-${LIBOGG_VERSION}.tar.gz" \
	'tar xzf' "sha256:${LIBOGG_SHA256}"

# Avoid compiling and installing doc
sed -ie 's/^\(SUBDIRS.*\) doc/\1/' Makefile.am
autoreconf -fi

do_configure_shared
do_make
do_make install

do_clean_bdir
