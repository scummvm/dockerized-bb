#! /bin/sh

LIBOGG_VERSION=80173bebc715cec66e95d0b8bc57d9424ca6d3b3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps2-libogg "https://github.com/citronalco/ps2-libogg/archive/${LIBOGG_VERSION}.tar.gz" 'tar xzf'

make -f Makefile.ps2
make -f Makefile.ps2 install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
