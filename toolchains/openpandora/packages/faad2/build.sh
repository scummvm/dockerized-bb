#! /bin/sh

# OpenPandora firmware uses faad2 2.7 stick with it
FAAD2_VERSION=2.7
FAAD2_SHA256=14561b5d6bc457e825bfd3921ae50a6648f377a9396eaf16d4b057b39a3f63b5

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch faad2 "http://download.sourceforge.net/project/faac/faad2-src/faad2-${FAAD2_VERSION}/faad2-${FAAD2_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${FAAD2_SHA256}"

# Avoid compiling and installing libfaad2_drm
sed -ie 's/^\(lib_LTLIBRARIES.*\) libfaad_drm.la/\1/' libfaad/Makefile.am

autoreconf -fi
do_configure_shared
do_make -C libfaad
do_make -C libfaad install

do_clean_bdir
