#! /bin/sh

SDL_VERSION=2.0.12

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# We need to get package directly from SDL because Debian source package doesn't have Windows specific files

# GPG key of Sam Lantinga
gpg --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xA7763BE6
do_http_fetch SDL2 "https://www.libsdl.org/release/SDL2-${SDL_VERSION}.tar.gz" 'tar xzf' \
	"gpgurl:https://www.libsdl.org/release/SDL2-${SDL_VERSION}.tar.gz.sig"
rm -Rf $HOME/.gnupg

do_configure --enable-shared --disable-static
do_make LDFLAGS="$LDFLAGS -Wc,-static-libgcc"
do_make install
$STRIP $DESTDIR/$PREFIX/bin/SDL2.dll

do_clean_bdir
