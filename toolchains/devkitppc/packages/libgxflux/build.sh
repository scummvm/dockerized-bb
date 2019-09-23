#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libgxflux \
	'https://repo.or.cz/libgxflux.git/snapshot/dd10b75242684165bc4b962f770eace08f426756.tar.gz' 'tar xzf'

do_make lib
do_make install

do_clean_bdir
