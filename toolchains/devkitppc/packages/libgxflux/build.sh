#! /bin/sh

GXFLUX_VERSION=91430ea95d976c2dc76e0c3ad49d001fc3b0f3ae

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libgxflux \
	"https://repo.or.cz/libgxflux.git/snapshot/${GXFLUX_VERSION}.tar.gz" 'tar xzf'

do_make lib
do_make install

do_clean_bdir
