#! /bin/sh

# Stick with toolchain version
JPEG_VERSION=6b
JPEG_SHA256=75c3ec241e9996504fe02a9ed4d12f16b74ade713972f3db9e65ce95cd27e35d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch jpeg "http://www.ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz" 'tar xzf' "sha256:${JPEG_SHA256}"

# Override config.guess and config.sub with modern versions
cp /usr/share/misc/config.guess /usr/share/misc/config.sub .

do_configure_shared --without-x --enable-shared --enable-static
do_make

# Don't install binaries and doc
do_make install-lib

do_clean_bdir
