#! /bin/sh

TOOLCHAIN_VERSION=c2668ff05b57ac7cac847c86867a0c46a3fba16f
export PSPSDK_VERSION=1d32cbfe0418850013e374e97faf2589d9f6ef82
export NEWLIB_VERSION=f8d6259c204fd0fa76e01926ec4e3e4fe04f6b22
export PSPLINKUSB_VERSION=9a9512ed115c3415ac953b64613d53283a75ada9
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSP_PKGCONF_VERSION=c50b45fd551c08eefebd9cb02edc55887fd68b28
export PSPLIBRARIES_VERSION=a909bc116231e0123ee9f1eaf5145155fd0d6440

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
