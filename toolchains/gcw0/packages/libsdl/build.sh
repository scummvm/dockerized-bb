#! /bin/sh

# Stick with toolchain version
SDL_VERSION=1.2.15

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key of Sam Lantinga
gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 0xA7763BE6
do_http_fetch SDL "https://www.libsdl.org/release/SDL-${SDL_VERSION}.tar.gz" 'tar xzf' \
	"gpgurl:http://www.libsdl.org/release/SDL-${SDL_VERSION}.tar.gz.sig"
rm -Rf $HOME/.gnupg

./autogen.sh

# The test fails because of cross-compilation
# DOn't know why but linuxev is disabled on official toolchain, force it here
export ac_cv_func_memcmp_working=yes
do_configure_shared \
	--enable-rpath=no \
	--enable-video-fbcon=yes \
	--enable-video-x11=no \
	--enable-input-events=no

do_make

# No man pages
do_make install-bin install-hdrs install-lib install-data

do_clean_bdir
