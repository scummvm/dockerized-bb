#! /bin/sh

UCON64_VERSION=2.2.1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ucon64 "https://sourceforge.net/projects/ucon64/files/ucon64/ucon64-${UCON64_VERSION}/ucon64-${UCON64_VERSION}-src.tar.gz/download" 'tar xzf'

cd src

./configure

do_make
do_make install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
