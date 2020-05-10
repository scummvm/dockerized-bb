#! /bin/sh

# OpenPandora firmware uses alsa-lib 1.0.20 stick with it
ALSA_LIB_VERSION=1.0.20
ALSA_LIB_SHA256=15f8d0eef1da10c62136107e7b585bc8beb9c9e9b7ad177654097f8c15e57a63

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch alsa-lib "http://www.alsa-project.org/files/pub/lib/alsa-lib-${ALSA_LIB_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${ALSA_LIB_SHA256}"

# Enable shared objects to make binary lighter
do_configure_shared --disable-python

# Only build src and include
do_make -C src
do_make -C include

do_make -C src install-exec
do_make -C include install

do_clean_bdir
