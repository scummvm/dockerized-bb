#! /bin/sh

# Stick with toolchain version
LIBICONV_VERSION=1.14

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key used for signing 1.14 is unknown...
do_http_fetch libiconv "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz" 'tar xzf'

do_configure

do_make

# Only install library
do_make install-lib

do_clean_bdir
