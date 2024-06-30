#! /bin/sh

PSPDEV_VERSION=8a5d35da2c3e0e4916e3a09f51a30717285bb3d6
export PSPTOOLCHAIN_VERSION=a420edb56fd5e63f21a043748b14ea2c7925bb48
export PSPSDK_VERSION=5549b547607862407b6848d208bb553b9e1b36fa
export PSPLINKUSB_VERSION=7fc1352bc546701f49c9f33c501376ffad684188
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=cdfaf141b899030c1188f6ee67302e2a7a5cd39f
export PSPTOOLCHAIN_EXTRA_VERSION=a9532d80f733088c781f711eceef6471a585193d
export BINUTILS_VERSION=982f4d2cb190f0bce06a98e7556b1b20a256d826
export GCC_VERSION=9dc41f8ec692e2028838f67676ba956be62c0896
export NEWLIB_VERSION=e2e50477342e32dd9a78143264dc4d15adb9fddb
export PTHREAD_EMBEDDED_VERSION=4f43d30a23e8ac6d0334aef64272b4052b5bb7c2
export PSP_PACMAN_VERSION=53603eccf7748de0fff614848a4020b52b1c5e31

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
