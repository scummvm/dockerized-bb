#! /bin/sh

MAKERUN_VERSION=57097e214b1b0f5c898368d22cf61b2a7c8caf50

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch makerun "git://git.netsurf-browser.org/makerun.git" "${MAKERUN_VERSION}"

gcc -o makerun makerun.c

mkdir -p "$GCCSDK_INSTALL_CROSSBIN"
cp makerun "$GCCSDK_INSTALL_CROSSBIN"

do_clean_bdir
