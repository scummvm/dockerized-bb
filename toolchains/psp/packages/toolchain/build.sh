#! /bin/sh

PSPDEV_VERSION=d1be8a70177d4c659fb6513e8ed2363acb1df360
export PSPTOOLCHAIN_VERSION=a420edb56fd5e63f21a043748b14ea2c7925bb48
export PSPSDK_VERSION=d1d5dcf05d37fc6f7a147d1f8abb0d2c467f1a4d
export PSPLINKUSB_VERSION=00cd43b0ee41b5a037346616453abc7dffbb48d5
export EBOOTSIGNER_VERSION=17d6386f034ac922f540ca78200961761b23ecae
export PSPTOOLCHAIN_ALLEGREX_VERSION=6e225c051bbad644707dc428abe4a1957a8be469
export PSPTOOLCHAIN_EXTRA_VERSION=a9532d80f733088c781f711eceef6471a585193d
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
