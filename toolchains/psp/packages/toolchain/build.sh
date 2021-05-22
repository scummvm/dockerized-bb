#! /bin/sh

TOOLCHAIN_VERSION=c2668ff05b57ac7cac847c86867a0c46a3fba16f
export PSPSDK_VERSION=1d32cbfe0418850013e374e97faf2589d9f6ef82
export NEWLIB_VERSION=6b44911b058f4a7b933339c1a941ff698504e90c
export PSPLINKUSB_VERSION=9a9512ed115c3415ac953b64613d53283a75ada9
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSP_PKGCONF_VERSION=c50b45fd551c08eefebd9cb02edc55887fd68b28
export PSPLIBRARIES_VERSION=043813f1db67c70a90a836f9ddec40ff18237969

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch psptoolchain "https://github.com/pspdev/psptoolchain/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# export PATH to please toolchain.sh
export PATH=$PATH:$PSPDEV/bin
# export ACLOCAL_PATH for SDL aclocal macros (avoids installation of libsdl on host)
export ACLOCAL_PATH=$PREFIX/share/aclocal:$ACLOCAL_PATH

# Use -e to stop on error
# Don't write environment variables to profile.d (like in toolchain-local.sh)
bash -e ./toolchain.sh $(seq 1 12)

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
