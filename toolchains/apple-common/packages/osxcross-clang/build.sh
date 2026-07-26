#! /bin/sh

OSXCROSS_VERSION=27d21e4977c9751d01199c7a226a6faf494c3dd9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch osxcross "https://github.com/tpoechtrager/osxcross.git" "${OSXCROSS_VERSION}"

# Don't ask anything
UNATTENDED=1 \
	ENABLE_CLANG_INSTALL=1 \
	INSTALLPREFIX="${TARGET_DIR}" \
	./build_clang.sh

do_clean_bdir
