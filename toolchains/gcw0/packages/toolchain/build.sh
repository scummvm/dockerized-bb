#! /bin/sh

CT_NG_VERSION=1.24.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG keys of Bryan Hundven and Alexey Neyman
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x35B871D1 0x11D618A4
do_http_fetch crosstool-ng "http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CT_NG_VERSION}.tar.bz2" 'tar xjf' \
	"gpgurl:http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CT_NG_VERSION}.tar.bz2.sig"
rm -Rf $HOME/.gnupg

# Update everything as we just patched Crosstool
./bootstrap

# Don't use do_configure as it's a pure host job
./configure --enable-local
make

# Create tarballs directory
mkdir -p ./.tarballs

# Update configuration
cp ${PACKAGE_DIR}/config .config
./ct-ng olddefconfig
cp ${PACKAGE_DIR}/uclibc.config uclibc.config

./ct-ng build CT_PREFIX=${GCW_TOOLCHAIN}

do_clean_bdir
# Cleanup stuff left by crosstool-ng
rm -f $HOME/.wget-hsts
rm -f /tmp/cc*
