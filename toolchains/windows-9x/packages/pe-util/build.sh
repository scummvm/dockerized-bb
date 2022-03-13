#! /bin/sh

PE_UTIL_VERSION=2af684a0acf303bc23b1c970f0251291cdd69189

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch pe-util 'https://github.com/gsauthof/pe-util.git' "$PE_UTIL_VERSION"

do_cmake "$@"
do_make
do_make install

do_clean_bdir
