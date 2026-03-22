#! /bin/sh

BANNERTOOL_VERSION=39631b3c936a0a23775d5c80ce1866c0be0e82ad

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch bannertool \
	'https://github.com/carstene1ns/3ds-bannertool.git' "${BANNERTOOL_VERSION}"

do_cmake -DCMAKE_INSTALL_PREFIX=${DEVKITPRO}/tools
do_make
do_make install

do_clean_bdir
