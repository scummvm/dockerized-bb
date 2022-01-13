#! /bin/sh

# Stick with toolchain version
JPEG_VERSION=8d
JPEG_SHA256=fdc4d4c11338ad028a7d23fb53f5bb9354671392a67fb1b52e0c32a7121891f8

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch jpeg "http://www.ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz" 'tar xzf' "sha256:${JPEG_SHA256}"

do_configure_shared
do_make

# Don't install binaries and doc
do_make install-libLTLIBRARIES \
	install-data-local \
	install-includeHEADERS

do_clean_bdir
