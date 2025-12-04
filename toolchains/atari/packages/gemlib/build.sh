#! /bin/sh

GEMLIB_VERSION=958583a

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch gemlib "https://github.com/freemint/gemlib/archive/${GEMLIB_VERSION}.tar.gz" 'tar xf'

do_make CROSS_TOOL=${HOST} DESTDIR=${PREFIX} PREFIX=""
do_make CROSS_TOOL=${HOST} DESTDIR=${PREFIX} PREFIX="" install

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
