#! /bin/sh

XAR_VERSION=fb897139262d7ac5c9e187a9f9c219255f465983

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch xar "https://github.com/tpoechtrager/xar.git" "${XAR_VERSION}"

cd xar

# Install globally else it's not found.
# No need of static as it doesn't link with cctools_port
./configure --prefix="/usr" --disable-static

do_make

do_make install

do_clean_bdir
