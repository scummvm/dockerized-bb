#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch "" 'http://web.archive.org/web/20181110025829/http://www.open2x.org/open2x/toolchains/open2x-libpack-20071903-gcc-4.1.1-glibc-2.3.6.tar.bz2.zip' 'tar xjf'
cp -r bin include lib ${PREFIX}

do_clean_bdir
