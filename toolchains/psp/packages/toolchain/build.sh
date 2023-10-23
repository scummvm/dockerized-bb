#! /bin/sh

PSPDEV_VERSION=b0ef1ab7c1d7f999265cb13af4958ca111cc40e8
export PSPTOOLCHAIN_VERSION=1597b22623cab2bf83a9ebee5468e6a16fdfb575
export PSPSDK_VERSION=2f723c3b8280100c1d77d74d23e37d58f7423506
export PSPLINKUSB_VERSION=d8c81925bf7e7bbad3303ec099ffc987a58b309d
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSPTOOLCHAIN_ALLEGREX_VERSION=4fcb76770b01ebb46f3362050e283c8b636ad91e
export PSPTOOLCHAIN_EXTRA_VERSION=058c56116febfd0ffbbf78195d6fdfa66a6a4a3a
export BINUTILS_VERSION=1bf9b3f9be9d82cc89374ca916cd4e8e6115dcf8
export GCC_VERSION=65cf73279bb91ff72e5327dd1621c206f027f761
export NEWLIB_VERSION=5c65a2e32e2caba2752b5c5f811a3f515491555e
export PTHREAD_EMBEDDED_VERSION=c7e2d5a7e810401174b0484979b6d29a2f1ab519
export PSP_PACMAN_VERSION=aedc04981cd6125741916e0b4b1b4d42715af6fa

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
