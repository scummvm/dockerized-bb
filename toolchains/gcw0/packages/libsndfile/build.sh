#! /bin/sh

# Stick with toolchain version
LIBSNDFILE_VERSION=1.0.25
LIBSNDFILE_SHA256=59016dbd326abe7e2366ded5c344c853829bebfd1702ef26a07ef662d6aa4882

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libsndfile "http://www.mega-nerd.com/libsndfile/files/libsndfile-${LIBSNDFILE_VERSION}.tar.gz" \
	'tar xzf' "sha256:${LIBSNDFILE_SHA256}"

sed -i -e 's/^SUBDIRS = .*$/SUBDIRS = src/' Makefile.in

do_configure_shared

do_make
do_make install

do_clean_bdir
