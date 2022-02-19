#! /bin/sh

PSPDEV_VERSION=9af210e25b3e83dcad57b26985b437146efef97a
export PSPTOOLCHAIN_VERSION=b6c1547ee82eada94dcb07acdcfd7fd40a3f4421
export PSPSDK_VERSION=aa211afe19acd5c178b1d8fb45fb4076237cbe9f
export PSPLINKUSB_VERSION=dbf5b94dd973dc49ee28d596a03c1362bcbce9e3
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSPTOOLCHAIN_ALLEGREX_VERSION=e042e2e4b5ae8e9377cc18cab2cc14e27a9135f0
export PSPTOOLCHAIN_EXTRA_VERSION=880705e1993a43c8e0533e53e67bab6f3b57e202
export BINUTILS_VERSION=e9c864fd3776b1fef2e374568e47f442ec58c773
export GCC_VERSION=873f9ff28c1ce079d48ca53f845fe0c88fa6961b
export NEWLIB_VERSION=b9c77d5302e4bb56196127fed1ca06fb6ee75a01
export PSP_PACMAN_VERSION=23e6b9389626a32336063e90c486aa4db73a74d7

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
