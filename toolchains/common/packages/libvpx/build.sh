#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libvpx

do_configure --disable-examples --disable-tools --disable-docs --disable-unit-tests --disable-install-bins --disable-install-srcs \
	--size-limit=16384x16384 --disable-vp8-encoder --disable-vp9-encoder \
	"$@"
do_make
do_make install

do_clean_bdir
