#! /bin/sh

PSPDEV_VERSION=eec6b217856c83b24b7b4b326238e0db323e55a6
export PSPTOOLCHAIN_VERSION=10ef17d71ee4afd09e36069a38d727391d902b50
export PSPSDK_VERSION=8fc8beb72ab46ee9b6922505f0c1da199114c48a
export PSPLINKUSB_VERSION=694aa1e390c9b7ffbb882e667781aca14cb44659
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=30ce261f43227bac95b5286c15be722ed61de7a6
export PSPTOOLCHAIN_EXTRA_VERSION=a80c9c8bb7fc2dbf0fa1407547307474c1bfa012
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
