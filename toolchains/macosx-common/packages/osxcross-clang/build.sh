#! /bin/sh

OSXCROSS_VERSION=45d2f7ec2ee68c9ad51d590869609b5b3b028605

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
