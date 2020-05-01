#! /bin/sh

TOOLCHAIN_REVISION=376

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

# Don't run open2x-gp2x-apps.sh as it hardcodes all paths, and ask for confirmation
# Just do the same

do_make_bdir

do_svn_fetch "open2x-toolchain" 'https://svn.code.sourceforge.net/p/open2x/code/trunk/toolchain-new' "${TOOLCHAIN_REVISION}"

export TARBALLS_DIR="$(pwd)/sources"
# PREFIX is already exported and it matters way more than RESULT_TOP
export RESULT_TOP="${PREFIX}"
export GCC_LANGUAGES="c,c++"

mkdir -p "${RESULT_TOP}"
mkdir -p "${TARBALLS_DIR}"

eval `cat arm-gp2x.dat gcc-4.1.1-glibc-2.3.6-hdrs-gp2x.dat`  sh all.sh --notest

# Remove leftover files
rm -f /tmp/cc*

do_clean_bdir
rm -rf ${HOME}/.subversion
