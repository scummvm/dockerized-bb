#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

for f in "${PACKAGE_DIR}"/*; do
	if [ "$(basename "$f")" = "build.sh" ]; then
		continue
	fi
	cp "$f" "${CROSS_PREFIX}/bin/"
done

# gdate is exactly the GNU date
ln -s /bin/date "${CROSS_PREFIX}/bin/gdate"
