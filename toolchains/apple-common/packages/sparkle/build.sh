#! /bin/sh

SPARKLE_VERSION=2.6.3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Sparkle "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" 'tar --one-top-level -xJf'

# Remove XPCServices
rm "Sparkle.framework/XPCServices"
rm -rf "Sparkle.framework/Versions/B/XPCServices"

# Sign remaining binaries: our codesign shim doesn't handle well deep binaries
ldid -P -Cadhoc -Cruntime -S Sparkle.framework/Versions/B/Autoupdate
ldid -P -Cadhoc -Cruntime -S Sparkle.framework/Versions/B/Updater.app

mkdir -p "${DESTDIR}/${PREFIX}/Library/Frameworks"

mv Sparkle.framework "${DESTDIR}/${PREFIX}/Library/Frameworks"

# Don't copy bin dir as we won't be able to run it

do_clean_bdir
