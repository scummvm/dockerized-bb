#! /bin/sh

VERSION=0.16

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Project_CTR "https://github.com/jakcron/Project_CTR/archive/v${VERSION}.tar.gz" 'tar xzf'

export

do_make -C ctrtool
do_make -C makerom

cp ctrtool/ctrtool makerom/makerom ${DEVKITPRO}/tools/bin

do_clean_bdir
