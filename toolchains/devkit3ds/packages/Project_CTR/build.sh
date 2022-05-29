#! /bin/sh

PROJECT_CTR_VERSION=makerom-v0.18.3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Project_CTR "https://github.com/3DSGuy/Project_CTR/archive/${PROJECT_CTR_VERSION}.tar.gz" 'tar xzf'

export

do_make -C ctrtool deps
do_make -C ctrtool all

do_make -C makerom deps
do_make -C makerom all

cp ctrtool/bin/ctrtool makerom/bin/makerom ${DEVKITPRO}/tools/bin

do_clean_bdir
