#! /bin/sh

LIBTREMOR_VERSION=ae62505aee8f4fc15cce97332133229ed8da0d5a

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps2-libtremor "https://github.com/citronalco/ps2-libtremor/archive/${LIBTREMOR_VERSION}.tar.gz" 'tar xzf'

make -f Makefile.ps2
make -f Makefile.ps2 install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
