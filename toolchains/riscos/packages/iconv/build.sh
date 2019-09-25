#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libiconv 'https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz' 'tar xzf'

./configure --prefix=/usr/local --disable-shared --enable-extra-encodings "$@"
do_make
do_make install

do_clean_bdir
