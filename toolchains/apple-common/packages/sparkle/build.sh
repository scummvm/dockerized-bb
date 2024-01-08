#! /bin/sh

SPARKLE_VERSION=2.5.2

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Sparkle "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" 'tar --one-top-level -xJf'

mkdir -p "${DESTDIR}/${PREFIX}/Library/Frameworks"

mv Sparkle.framework "${DESTDIR}/${PREFIX}/Library/Frameworks"

# Don't copy bin dir as we won't be able to run it

do_clean_bdir
