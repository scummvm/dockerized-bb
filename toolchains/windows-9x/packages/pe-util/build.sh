#! /bin/sh

PE_UTIL_VERSION=5b07cb3586a1da687a2c5845f1207e054e74c5cd

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch pe-util 'https://github.com/gsauthof/pe-util.git' "$PE_UTIL_VERSION"

do_cmake "$@"
do_make
do_make install

do_clean_bdir
