#! /bin/sh

# Use 1.2.13 as it's the one provided by Caanoo official toolchain
# Patch has been made from Openwiz project, and RE of the original .so
SDL_VERSION=1.2.13

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

do_configure_shared \
	--disable-static \
	--enable-video \
	--enable-video-fbcon

do_make

# No man pages
do_make install-bin install-hdrs install-lib install-data

do_clean_bdir
