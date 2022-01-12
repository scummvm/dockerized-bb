#! /bin/sh

PSPDEV_VERSION=9af210e25b3e83dcad57b26985b437146efef97a
export PSPTOOLCHAIN_VERSION=b6c1547ee82eada94dcb07acdcfd7fd40a3f4421
export PSPSDK_VERSION=304c93a96979a970ff68dffc07688ef5f149cae4
export PSPLINKUSB_VERSION=dbf5b94dd973dc49ee28d596a03c1362bcbce9e3
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSPTOOLCHAIN_ALLEGREX_VERSION=11942d2a69c9e96e9e1465b315488b0ffb4df819
export PSPTOOLCHAIN_EXTRA_VERSION=880705e1993a43c8e0533e53e67bab6f3b57e202
export BINUTILS_VERSION=684a872506aeda6c6ac37074df24e5d5ce23e808
export GCC_VERSION=0049612a76e8f44b9c21646cb90ca4bad8f4aff3
export NEWLIB_VERSION=dd3c854d70d2a0b4293569433d262c9ade4d60a0
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
