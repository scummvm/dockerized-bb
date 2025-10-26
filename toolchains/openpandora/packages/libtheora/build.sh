#! /bin/sh

# OpenPandora firmware uses libtheora 1.1.1 (ABI 0.3.10) stick with it
LIBTHEORA_VERSION=1.1.1
LIBTHEORA_SHA256=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libtheora "http://downloads.xiph.org/releases/theora/libtheora-${LIBTHEORA_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${LIBTHEORA_SHA256}"

# Don't run autoreconf as we miss some M4 files

# Avoid compiling and installing doc
sed -ie 's/^\(SUBDIRS.*\) doc/\1/' Makefile.in

do_configure_shared --disable-examples
do_make
do_make install

do_clean_bdir
