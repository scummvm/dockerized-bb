#! /bin/sh

THEORA_VERSION=23161c4a63fd9f9d09b9e972f95def2d56c777af

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch theora "https://gitlab.xiph.org/xiph/theora/-/archive/${THEORA_VERSION}/theora-${THEORA_VERSION}.tar.gz" 'tar xzf'

# Avoid compiling and installing doc
sed -ie 's/^\(SUBDIRS.*\) doc/\1/' Makefile.am

autoreconf -fi -I m4
do_configure --disable-examples --disable-spec --disable-doc "$@"
do_make V=1
do_make install

do_clean_bdir
