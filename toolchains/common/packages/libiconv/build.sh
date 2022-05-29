#! /bin/sh

LIBICONV_VERSION=1.17

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key of Bruno Haible (Open Source Development) <bruno@clisp.org>
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0xF5BE8B267C6A406D
do_http_fetch libiconv "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz" 'tar xzf' \
	"gpgurl:http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz.sig"
rm -Rf $HOME/.gnupg

do_configure

do_make

# Only install library
do_make install-lib

do_clean_bdir
