#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch WinSparkle 'https://github.com/vslavik/winsparkle/releases/download/v0.6.0/WinSparkle-0.6.0.zip' 'unzip'

# Remove PDB files
rm -f Release/*.pdb x64/Release/*.pdb

mkdir -p $DESTDIR/$PREFIX/lib $DESTDIR/$PREFIX/include
case "$HOST" in
	x86_64*)
		cp -a x64/Release/* $DESTDIR/$PREFIX/lib
		;;
	i686*)
		cp -a Release/* $DESTDIR/$PREFIX/lib
		;;
esac
cp -a include/* $DESTDIR/$PREFIX/include

do_clean_bdir
