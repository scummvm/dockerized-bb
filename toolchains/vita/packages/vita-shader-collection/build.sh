#! /bin/sh

VITA_SHDR_COLL_VERSION=gtu-0.1-v79

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

PKG=vita-shader-collection

if [ -d "$PKG" ]; then
	rm -r "$PKG"
fi
mkdir "$PKG"
cd "$PKG"

# Don't use do_http_get as the archive doesn't have a root directory
wget --no-hsts --progress=dot \
	"https://github.com/frangarcj/vita-shader-collection/releases/download/${VITA_SHDR_COLL_VERSION}/vita-shader-collection.tar.gz" -O - | \
	tar --no-same-owner --no-same-permissions -xz

cp -a lib/. $DESTDIR/$PREFIX/lib/
cp -a includes/. $DESTDIR/$PREFIX/include/

do_clean_bdir
