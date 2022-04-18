#! /bin/sh

BANNERTOOL_VERSION=f4ce9e638713c26bd76bad9bdbbfce7f023a29c6

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch bannertool \
	'https://github.com/marius851000/bannertool.git' "${BANNERTOOL_VERSION}"

do_make

# Don't install with Makefile as it isn't configurable
cp output/*/bannertool ${DEVKITPRO}/tools/bin

do_clean_bdir
