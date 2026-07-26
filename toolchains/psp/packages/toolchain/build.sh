#! /bin/sh

PSPDEV_VERSION=8d581609506117f6c8fa77893a2f38e4ad4b39fe
export PSPTOOLCHAIN_VERSION=57a4fc650324dea4637ea5ef9dfc2fc292c004f8
export PSPSDK_VERSION=8c74232c1db67ffb3253cb9cc7a0e38298b4cf57
export PSPLINKUSB_VERSION=8cc9876a868d202c0ef4197395c5278aeeff2829
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=a95b7da838d9f506656092c3e0232dcf50389d89
export PSPTOOLCHAIN_EXTRA_VERSION=b5f01b00e428a604832e0dfb4bfbb991d1397e3f
export BINUTILS_VERSION=a8b53fe2b5825fa86337623c743d21a19aeb0daf
export GCC_VERSION=1a33997924916ff5a6f61b64179ff9c8921f46c6
export NEWLIB_VERSION=9e0a073634ad73e8e088f2e071c55a9fe5d39709
export PTHREAD_EMBEDDED_VERSION=97fe4ce006b420894f2bcaeb530d1f1f53111fc2
export PSP_PACMAN_VERSION=e1423621af5a821b441bc9db69db62fa0497288b

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
