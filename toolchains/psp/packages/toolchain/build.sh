#! /bin/sh

PSPDEV_VERSION=f6546119b457cb441a8d422e184be9f1f1a96f24
export PSPTOOLCHAIN_VERSION=4d1e6670ea2bb5a9d60033df889ef8f1bad22c5f
export PSPSDK_VERSION=b3f0fb5f5029cc3a6085a9b489509c647963b0d8
export PSPLINKUSB_VERSION=288a088971af1be21182344bceca82d6a7045c05
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=ab90c1274acc7269f213852f85abaf81b4b6a56d
export PSPTOOLCHAIN_EXTRA_VERSION=12339428164a243978d0d4dc40e1507cd6962bb8
export BINUTILS_VERSION=a8b53fe2b5825fa86337623c743d21a19aeb0daf
export GCC_VERSION=33e5b187fa86c429c8827f6e12f120eab7d51c9e
export NEWLIB_VERSION=9e0a073634ad73e8e088f2e071c55a9fe5d39709
export PTHREAD_EMBEDDED_VERSION=4f43d30a23e8ac6d0334aef64272b4052b5bb7c2
export PSP_PACMAN_VERSION=a62b15e26919be932c1050c1c3f957193e7fdbe2

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
