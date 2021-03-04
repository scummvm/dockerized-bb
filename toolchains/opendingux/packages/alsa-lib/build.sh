#! /bin/sh

# Stick with toolchain version
ALSA_LIB_VERSION=1.0.24.1
ALSA_LIB_SHA256=a32f7c21015b6c71f9a80ff70a2b6a50e4ff4d5c77c744ff0793dea7ba7a2517

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch alsa-lib "http://www.alsa-project.org/files/pub/lib/alsa-lib-${ALSA_LIB_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${ALSA_LIB_SHA256}"

# Enable shared objects to make binary lighter
do_configure_shared \
	--enable-static \
	--without-versioned \
	--disable-rawmidi \
	--disable-alisp \
	--disable-seq \
	--disable-old-symbols \
	--disable-python \
	--with-softfloat

# Only build src and include
do_make -C src
do_make -C include

do_make -C src install-exec
do_make -C include install

do_clean_bdir
