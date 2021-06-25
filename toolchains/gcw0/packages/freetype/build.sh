#! /bin/sh

# Stick with toolchain version
FREETYPE_VERSION=2.5.3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key of Werner Lemberg <wl@gnu.org> 
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0xC1A60EACE707FDA5
do_http_fetch freetype "http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.bz2" \
       'tar xjf' "gpgurl:http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.bz2.sig"
rm -Rf $HOME/.gnupg

do_configure_shared
do_make
do_make install

do_clean_bdir
