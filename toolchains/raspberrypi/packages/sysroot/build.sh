#! /bin/sh
RASPBIAN_VERSION=bullseye

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

sysroot="$(pwd)/sysroot"
mkdir -p "$sysroot"

# Download Raspbian key directly in sysroot
mkdir -p "$sysroot/etc/apt/trusted.gpg.d"
wget "http://raspbian.raspberrypi.org/raspbian.public.key" -O - | apt-key --keyring "$sysroot/etc/apt/trusted.gpg.d/raspbian.gpg" add -
wget "http://archive.raspberrypi.org/debian/raspberrypi.gpg.key" -O - | apt-key --keyring "$sysroot/etc/apt/trusted.gpg.d/raspberrypî.gpg" add -

# Build a multistrap config file
cat <<EOF >./multistrap.conf
[General]
arch=armhf
unpack=true
cleanup=true
bootstrap=raspbian raspberrypi
aptsources=

[raspbian]
packages=$@
source=http://raspbian.raspberrypi.org/raspbian/
keyring=
suite=$RASPBIAN_VERSION main contrib non-free rpi
omitdebsrc=true

[raspberrypi]
packages=$@
source=http://archive.raspberrypi.org/debian/
keyring=
suite=$RASPBIAN_VERSION main
omitdebsrc=true
EOF

multistrap -f multistrap.conf -d "$sysroot"

# Copy only sysroot bits we need
mkdir -p "$RPI_ROOT" "$RPI_ROOT/usr" "$RPI_ROOT/usr/bin"\
	"$RPI_ROOT/opt/vc"
mv "$sysroot/lib" "$RPI_ROOT/"
for f in "$sysroot/usr/bin/"*-config; do
	if ! [ -e "$f" ]; then
		# glob failed
		break
	fi
	# Pass on native binaries
	if ! echo -n "#!" | cmp -sn 2 "$f" -; then
		continue
	fi

	# Patch prefix path
	sed -i -e "s|^\\(prefix=.*\\)/usr|\\1$RPI_ROOT/usr|" "$f"

	mv "$f" "$RPI_ROOT/usr/bin/"
done
mv "$sysroot/usr/include" "$RPI_ROOT/usr/"
mv "$sysroot/usr/lib" "$RPI_ROOT/usr/"
if [ -d "$sysroot/opt/vc/include" ]; then
	mv "$sysroot/opt/vc/include" "$RPI_ROOT/opt/vc/"
	mv "$sysroot/opt/vc/lib" "$RPI_ROOT/opt/vc/"
fi

# This loop is way too verbose
set +x
# Fixup absolute links
find "$RPI_ROOT" -type l | while read f; do
	target=$(readlink "$f")
	if [ "${target#/}" = "${target}" ]; then
		# Not beginning with /: relative
		continue
	fi
	ln -rsf "${RPI_ROOT}/${target}" "$f"
	echo "Fixing $f -> $(readlink "$f")"
done
set -x

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
