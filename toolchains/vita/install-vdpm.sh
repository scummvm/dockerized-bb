#! /bin/sh

HELPERS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. $HELPERS_DIR/functions.sh

do_make_bdir

PACKAGE_NAME=$1
do_vdpm_fetch "$PACKAGE_NAME"
do_vdpm_install

do_clean_bdir
