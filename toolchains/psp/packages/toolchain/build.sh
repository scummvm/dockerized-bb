#! /bin/sh

PSPDEV_VERSION=f6977f7b749fec33aa44cac0cf07aed5b31d5d7b
export PSPTOOLCHAIN_VERSION=a420edb56fd5e63f21a043748b14ea2c7925bb48
export PSPSDK_VERSION=1a33b06ba3fc6478da987672011f5cb7e4a8347a
export PSPLINKUSB_VERSION=7d44fc10222df2d6f56d939ed4a15dc859651f4a
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=e3e1bed110ff0b13f490873d0f83ecbff9cf27c7
export PSPTOOLCHAIN_EXTRA_VERSION=3c9aa25abb47bb861523c17977f080b3682cad62
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
