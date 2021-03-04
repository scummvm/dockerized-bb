#! /bin/sh

# Stick with toolchain version (SVN revision 16259)
LIBTREMOR_VERSION=4ce4ec7859e7f8074341cfb00af1c207f5d24d3f

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
