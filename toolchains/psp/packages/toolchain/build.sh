#! /bin/sh

PSPDEV_VERSION=681088f7a4eaae47da5a4b277c12f27de3e9afbc
export PSPTOOLCHAIN_VERSION=0a5aa11b2cdae216d60f773e6667799073f2819e
export PSPSDK_VERSION=e62057d9724443cf498c5fddda0e3520bc13ca20
export PSPLINKUSB_VERSION=8cc9876a868d202c0ef4197395c5278aeeff2829
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=57a511e50c97a70d3da4e2a9a9b15e2dcedafd2d
export PSPTOOLCHAIN_EXTRA_VERSION=ce8127a5d7de5a8774bf1f7f152501dae0a800ae
export BINUTILS_VERSION=a8b53fe2b5825fa86337623c743d21a19aeb0daf
export GCC_VERSION=1a33997924916ff5a6f61b64179ff9c8921f46c6
export NEWLIB_VERSION=9e0a073634ad73e8e088f2e071c55a9fe5d39709
export PTHREAD_EMBEDDED_VERSION=97fe4ce006b420894f2bcaeb530d1f1f53111fc2
export PSP_PACMAN_VERSION=86787c81fc8ebd88f766dd79e880f20f2477d59e

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
