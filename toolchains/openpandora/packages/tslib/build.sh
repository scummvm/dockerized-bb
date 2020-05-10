#! /bin/sh

# Use the same version as the official toolchain
TSLIB_VERSION=1.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch tslib "https://github.com/libts/tslib/archive/${TSLIB_VERSION}.tar.gz" 'tar xzf'

# Remove configuration file and tests
sed -ie 's/^\(SUBDIRS.*\) etc\(.*\) tests/\1\2/' Makefile.am

./autogen.sh

do_configure_shared
do_make

do_make install

do_clean_bdir

