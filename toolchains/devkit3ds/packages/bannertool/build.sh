#! /bin/sh

BANNERTOOL_VERSION=5f297e49c8c72610caedd615958b960ec2bb0ab3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch bannertool \
	'https://github.com/Steveice10/bannertool.git' "${BANNERTOOL_VERSION}"

do_make

# Don't install with Makefile as it isn't configurable
cp output/*/bannertool ${DEVKITPRO}/tools/bin

do_clean_bdir
