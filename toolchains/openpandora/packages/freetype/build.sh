#! /bin/sh

# OpenPandora firmware uses freetype 2.3.9 stick with it
FREETYPE_VERSION=2.3.9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# GPG key of Werner Lemberg <wl@gnu.org> 
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0xC1A60EACE707FDA5
do_http_fetch freetype "http://download.savannah.gnu.org/releases/freetype/freetype-old/freetype-${FREETYPE_VERSION}.tar.bz2" \
       'tar xjf' "gpgurl:http://download.savannah.gnu.org/releases/freetype/freetype-old/freetype-${FREETYPE_VERSION}.tar.bz2.sig"
rm -Rf $HOME/.gnupg

# As in original toolchain, create a UNIX specific configure script and don't use zlib
# Script is not executable, call shell
# mmap test fails because we are cross-compiling but toolchain has it so force enable
/bin/sh ./autogen.sh

# We must export because sh keeps local to functions the variables assignments put in front of them
export ac_cv_func_mmap_fixed_mapped=yes
do_configure_shared --without-zlib
unset ac_cv_func_mmap_fixed_mapped

do_make
do_make install

do_clean_bdir
