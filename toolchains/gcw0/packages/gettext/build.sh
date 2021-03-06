#! /bin/sh

# Stick with toolchain version
GETTEXT_VERSION=0.18.3.2
GETTEXT_SHA256=d1a4e452d60eb407ab0305976529a45c18124bd518d976971ac6dc7aa8b4c5d7

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch gettext "https://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.gz" 'tar xzf' "sha256:${GETTEXT_SHA256}"

do_configure_shared -disable-libasprintf \
	--disable-acl \
	--disable-openmp \
	--disable-rpath \
	--disable-java \
	--disable-native-java \
	--disable-csharp \
	--disable-relocatable \
	--without-emacs \
	--enable-nls

# No binaries, no man, ...
do_make -C gettext-runtime/intl
do_make -C gettext-runtime/intl install

do_clean_bdir
