#! /bin/sh

# Stick with toolchain version
JPEG_VERSION=8d
JPEG_SHA256=d625ad6b3375a036bf30cd3b0b40e8dde08f0891bfd3a2960650654bdb50318c

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
