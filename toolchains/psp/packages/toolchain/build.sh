#! /bin/sh

PSPDEV_VERSION=99dee465c534679f16cc7e0d9fc6a5b92d759d7d
export PSPTOOLCHAIN_VERSION=57a4fc650324dea4637ea5ef9dfc2fc292c004f8
export PSPSDK_VERSION=6f15c154c902963864ea5c4538cc94febf8a2dad
export PSPLINKUSB_VERSION=e779d94779ff524c5bccd581ea4dafd001e00006
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=a95b7da838d9f506656092c3e0232dcf50389d89
export PSPTOOLCHAIN_EXTRA_VERSION=b5f01b00e428a604832e0dfb4bfbb991d1397e3f
export BINUTILS_VERSION=a8b53fe2b5825fa86337623c743d21a19aeb0daf
export GCC_VERSION=1a33997924916ff5a6f61b64179ff9c8921f46c6
export NEWLIB_VERSION=9e0a073634ad73e8e088f2e071c55a9fe5d39709
export PTHREAD_EMBEDDED_VERSION=97fe4ce006b420894f2bcaeb530d1f1f53111fc2
export PSP_PACMAN_VERSION=366221feba1309d3f92429138e6329eafe174193

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
