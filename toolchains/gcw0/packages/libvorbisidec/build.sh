#! /bin/sh

# Stick with toolchain version (SVN revision 18153)
LIBTREMOR_VERSION=189f68e9a31d644678c05e254dd212ba05317464

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
