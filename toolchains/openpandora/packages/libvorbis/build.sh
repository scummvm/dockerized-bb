#! /bin/sh

# OpenPandora firmware uses libvorbis 1.2.3 stick with it
LIBVORBIS_VERSION=1.2.3
LIBVORBIS_SHA256=c679d1e5e45a3ec8aceb5e71de8e3712630b7a6dec6952886c17435a65955947

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libvorbis "http://downloads.xiph.org/releases/vorbis/libvorbis-${LIBVORBIS_VERSION}.tar.gz" \
	'tar xzf' "sha256:${LIBVORBIS_SHA256}"

# Avoid compiling and installing useless stuff
sed -ie 's/^\(SUBDIRS.*\) examples test doc/\1/' Makefile.am

autoreconf -fi -I m4
do_configure_shared
do_make
do_make install

do_clean_bdir
