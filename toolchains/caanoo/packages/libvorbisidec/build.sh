#! /bin/sh

# Caanoo toolchain uses undetermined version of Tremor, use the most recent one which match headers and symbols list
LIBTREMOR_VERSION=afdecda7fe28e347380e98ca66a00cbbee4cd9f3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch tremor "https://gitlab.xiph.org/xiph/tremor/-/archive/${LIBTREMOR_VERSION}/tremor-${LIBTREMOR_VERSION}.tar.gz" \
	'tar xzf'

autoreconf -i
do_configure_shared
do_make
do_make install

do_clean_bdir
