#! /bin/sh

# Stick with toolchain version
LIBMAD_VERSION=0.15.1b
LIBMAD_SHA256=bbfac3ed6bfbc2823d3775ebb931087371e142bb0e9bb1bee51a76a6e0078690

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libmad "http://download.sourceforge.net/project/mad/libmad/${LIBMAD_VERSION}/libmad-${LIBMAD_VERSION}.tar.gz" \
	'tar xzf' "sha256:${LIBMAD_SHA256}"

touch NEWS AUTHORS ChangeLog
autoreconf -fi
do_configure_shared --disable-debugging --enable-speed
do_make
do_make install

do_clean_bdir
