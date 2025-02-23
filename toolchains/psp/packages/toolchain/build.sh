#! /bin/sh

PSPDEV_VERSION=5c1442695711ddc4fc3decbe52d56cbbb01e3426
export PSPTOOLCHAIN_VERSION=7e2541df014480cd399a013240161e2592f30878
export PSPSDK_VERSION=92a822d1b6009dac30ffa47224a7dc2d396eb886
export PSPLINKUSB_VERSION=7d44fc10222df2d6f56d939ed4a15dc859651f4a
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=cfde51aa074b16df52fe19af93092381fc087dc2
export PSPTOOLCHAIN_EXTRA_VERSION=12339428164a243978d0d4dc40e1507cd6962bb8
export BINUTILS_VERSION=982f4d2cb190f0bce06a98e7556b1b20a256d826
export GCC_VERSION=e8ee3aae2b5896b618464d155ed89d869ed5b110
export NEWLIB_VERSION=e2e50477342e32dd9a78143264dc4d15adb9fddb
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
