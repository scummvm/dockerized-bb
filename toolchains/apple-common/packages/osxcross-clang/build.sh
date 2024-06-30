#! /bin/sh

OSXCROSS_VERSION=fd32ecc6e0786369272be2da670bc9b5849b215a

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
