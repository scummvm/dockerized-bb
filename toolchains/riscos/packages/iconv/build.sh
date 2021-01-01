#! /bin/sh

LIBICONV_VERSION=1.16

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key of Bruno Haible (Open Source Development) <bruno@clisp.org>
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x4F494A942E4616C2
do_http_fetch libiconv "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz" 'tar xzf' \
	"gpgurl:http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz.sig"
rm -Rf $HOME/.gnupg

# We don't use do_configure as it's a native build
./configure --prefix="$GCCSDK_INSTALL_CROSSBIN/.." --disable-shared --enable-extra-encodings "$@"
do_make
# We install iconv binary here as we need it for build process
do_make install

do_clean_bdir
