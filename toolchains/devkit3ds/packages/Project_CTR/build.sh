#! /bin/sh

PROJECT_CTR_VERSION=makerom-v0.17

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Project_CTR "https://github.com/3DSGuy/Project_CTR/archive/${PROJECT_CTR_VERSION}.tar.gz" 'tar xzf'

export

do_make -C ctrtool
do_make -C makerom

cp ctrtool/ctrtool makerom/makerom ${DEVKITPRO}/tools/bin

do_clean_bdir
