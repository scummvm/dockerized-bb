#! /bin/sh

PSPDEV_VERSION=cc874700eaef9e00c8ec63e0d116926e1048b656
export PSPTOOLCHAIN_VERSION=73c98cece87b35d71a3dab678a7ecc71a19f1f06
export PSPSDK_VERSION=6c09d354398abc6523c165c57f83bc09eee8fc61
export PSPLINKUSB_VERSION=5794b808d36a10b09f2578d6fa5880bb91c2c9b4
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=a2a732924f91601ff7b99b477655d44482ce2a53
export PSPTOOLCHAIN_EXTRA_VERSION=ce8127a5d7de5a8774bf1f7f152501dae0a800ae
export BINUTILS_VERSION=a8b53fe2b5825fa86337623c743d21a19aeb0daf
export GCC_VERSION=33e5b187fa86c429c8827f6e12f120eab7d51c9e
export NEWLIB_VERSION=9e0a073634ad73e8e088f2e071c55a9fe5d39709
export PTHREAD_EMBEDDED_VERSION=4f43d30a23e8ac6d0334aef64272b4052b5bb7c2
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
