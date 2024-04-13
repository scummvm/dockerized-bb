#! /bin/sh

PSPDEV_VERSION=458a96d814f35799045021a0f4c222003f371a25
export PSPTOOLCHAIN_VERSION=ce32f9c7d782dd50817bc089712441ea9f5e28b2
export PSPSDK_VERSION=ae722cb5c1159aed6d0cf9edeaff6139fce171fb
export PSPLINKUSB_VERSION=b9156ada7647d3d011fa26c598c86f16597c17c7
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=74e301cf9ddae2ad9d1709ea90c98b4dc1be5c3d
export PSPTOOLCHAIN_EXTRA_VERSION=2e450099ed73395ee2bd2fed33b80b08202555a9
export BINUTILS_VERSION=1bf9b3f9be9d82cc89374ca916cd4e8e6115dcf8
export GCC_VERSION=cbd5840ad74d19923abd0a058764e0ac0dc3c575
export NEWLIB_VERSION=b8e1eb33d62ca778edf78f7254fba8ddd3d8911f
export PTHREAD_EMBEDDED_VERSION=4f43d30a23e8ac6d0334aef64272b4052b5bb7c2
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
