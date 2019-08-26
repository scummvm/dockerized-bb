#! /bin/sh

TOOLCHAIN_VERSION=a435ee0df19d8e07fa4c0a01f1f47fb7aeca834d

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
# Don't write environment variables to profile.d
bash -e ./toolchain.sh $(seq 1 11)

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
