#! /bin/sh

# Use lowmem branch of libtremor
LIBTREMOR_VERSION=89a7534bf2e70112e0354452b17a78675ca92dbf

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch tremor "https://gitlab.xiph.org/xiph/tremor/-/archive/${LIBTREMOR_VERSION}/tremor-${LIBTREMOR_VERSION}.tar.gz" \
	'tar xzf'

autoreconf -i
do_configure
do_make
do_make install

do_clean_bdir
