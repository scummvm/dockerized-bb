#! /bin/sh

PSPDEV_VERSION=d5c9ba96d8c6aafd23d0e4721617b657af5551bf
export PSPTOOLCHAIN_VERSION=10ef17d71ee4afd09e36069a38d727391d902b50
export PSPSDK_VERSION=7e595e52568e3c3a48accf5229a22d4b9bda54cd
export PSPLINKUSB_VERSION=1405de0fc59322914ae32fad3f29bf0506722f04
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=348e108470630c2abeadacfadd81b7256d1dfc5a
export PSPTOOLCHAIN_EXTRA_VERSION=9645ce8d3fe03d9e18192d99d1aaaaee3da57389
export BINUTILS_VERSION=1bf9b3f9be9d82cc89374ca916cd4e8e6115dcf8
export GCC_VERSION=cbd5840ad74d19923abd0a058764e0ac0dc3c575
export NEWLIB_VERSION=16a46371ad030c4b7f604e09e1ddb27b2e655169
export PTHREAD_EMBEDDED_VERSION=b1e378bfdc7e4ddae89ee3b76bab9f286821af1b
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
