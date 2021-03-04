#! /bin/sh

# Stick with toolchain version
LIBOGG_VERSION=1.3.1
LIBOGG_SHA256=4e343f07aa5a1de8e0fa1107042d472186b3470d846b20b115b964eba5bae554

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libogg "http://downloads.xiph.org/releases/ogg/libogg-${LIBOGG_VERSION}.tar.gz" \
	'tar xzf' "sha256:${LIBOGG_SHA256}"

# Avoid compiling and installing doc
sed -ie 's/^\(SUBDIRS.*\) doc/\1/' Makefile.am
autoreconf -fi

do_configure_shared
do_make
do_make install

do_clean_bdir
