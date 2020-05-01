#! /bin/sh

JPEG_VERSION=7
JPEG_SHA256=50b7866206c5be044c4a2b0d7895898f5a58d31b50e16e79cf7dea3b90337ebf

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
