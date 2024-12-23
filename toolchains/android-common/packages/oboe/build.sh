#! /bin/sh

OBOE_VERSION=1.9.3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch oboe "https://github.com/google/oboe/archive/refs/tags/${OBOE_VERSION}.tar.gz" 'tar xzf'

do_cmake
do_make
do_make install

do_clean_bdir
