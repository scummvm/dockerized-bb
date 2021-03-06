#! /bin/sh

# Stick with toolchain version
ALSA_LIB_VERSION=1.0.26
ALSA_LIB_SHA256=8c9f8161603cc3db640619650401292c3e110da63429ab6938aac763319f6e7d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch alsa-lib "http://www.alsa-project.org/files/pub/lib/alsa-lib-${ALSA_LIB_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${ALSA_LIB_SHA256}"

# Enable shared objects to make binary lighter
do_configure_shared \
	--without-versioned \
	--enable-static=no \
	--disable-alisp \
	--disable-old-symbols \
	--disable-python

# Only build src and include
do_make -C src
do_make -C include

do_make -C src install-exec
do_make -C include install
do_make -C utils install

do_clean_bdir
