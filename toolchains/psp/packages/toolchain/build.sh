#! /bin/sh

PSPDEV_VERSION=cfa3985528570adcf41c463d17e8d9d18376f19f
export PSPTOOLCHAIN_VERSION=1d5094187fa69a46a0ea52cbb3289b7a43db4b33
export PSPSDK_VERSION=62a9bc60ed77a0f99d9cdfbb743149a05e82e9a7
export PSPLINKUSB_VERSION=07c464bc11d6304107bbda68fa3fbd94b1b81101
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSPTOOLCHAIN_ALLEGREX_VERSION=19a924c3cd0785a678c10a7af90a2b5cd65365a3
export PSPTOOLCHAIN_EXTRA_VERSION=880705e1993a43c8e0533e53e67bab6f3b57e202
export BINUTILS_VERSION=1bf9b3f9be9d82cc89374ca916cd4e8e6115dcf8
export GCC_VERSION=65cf73279bb91ff72e5327dd1621c206f027f761
export NEWLIB_VERSION=034f72f6e21e211137d38ca4015a58c9ab82a369
export PTHREAD_EMBEDDED_VERSION=c7e2d5a7e810401174b0484979b6d29a2f1ab519
export PSP_PACMAN_VERSION=21c98d6d1268196084c0532127d04fcc28e25c5c

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch pspdev "https://github.com/pspdev/pspdev/archive/${PSPDEV_VERSION}.tar.gz" 'tar xzf'

# Don't install packages (yet)
rm -f scripts/*-psp-packages.sh

# export PATH to please the toolchain.sh
export PATH=$PATH:$PSPDEV/bin

# We use this variable in the patches
export PACKAGE_DIR
# Use -e to stop on error
bash -e ./build-all.sh

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts

# Remove pip cache
rm -rf $HOME/.cache
