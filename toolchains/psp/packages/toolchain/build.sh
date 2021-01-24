#! /bin/sh

TOOLCHAIN_VERSION=da322bfe4dbf10b8eee5d0e6473c3061a19acb12
export PSPSDK_VERSION=d1e5220c92fa5cd5c921a0255d38abad27966b09
export NEWLIB_VERSION=6dc26bb7f8bdc7dff72a811104e1d654d77f75d9
export PSPLINKUSB_VERSION=9a9512ed115c3415ac953b64613d53283a75ada9
export EBOOTSIGNER_VERSION=10cfbb51ea87adfe02d63dc3a262c8480fdf31e7
export PSP_PKGCONF_VERSION=c50b45fd551c08eefebd9cb02edc55887fd68b28
export PSPLIBRARIES_VERSION=8b0fb6f1fc8bc2804d52f76753dd604ca5a75f53

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch psptoolchain "https://github.com/pspdev/psptoolchain/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# export PATH to please toolchain.sh
export PATH=$PATH:$PSPDEV/bin
# export ACLOCAL_PATH for SDL aclocal macros (avoids installation of libsdl on host)
export ACLOCAL_PATH=$PREFIX/share/aclocal:$ACLOCAL_PATH

# Use -e to stop on error
# Don't write environment variables to profile.d (like in toolchain-local.sh)
bash -e ./toolchain.sh $(seq 1 12)

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
