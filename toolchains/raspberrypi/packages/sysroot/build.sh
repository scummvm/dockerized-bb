#! /bin/sh
RASPBIAN_VERSION=bookworm

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# Download Raspbian keys
wget "http://raspbian.raspberrypi.org/raspbian.public.key" -O - | gpg --dearmor -o "raspbian.gpg"
wget "http://archive.raspberrypi.org/debian/raspberrypi.gpg.key" -O - | gpg --dearmor -o "raspberrypi.gpg"

# We can't specify several sources and a directory target... Create a tar (using convoluted means) and extract it.
mkdir -p host
ln -s /usr/bin/tar host/

FAKECHROOT_EXCLUDE_PATH="$(pwd)/host" mmdebstrap --mode=fakeroot --variant=extract --architectures=armhf \
	--setup-hook="mkdir -p \$1/usr/bin/; ln -s $(pwd)/host/tar \$1/usr/bin/" \
	--include="$(echo "$@" | tr ' ' ',')">toolchain.tar <<EOF
deb [signed-by=$(pwd)/raspbian.gpg] http://raspbian.raspberrypi.org/raspbian/ $RASPBIAN_VERSION main contrib non-free rpi
deb [signed-by=$(pwd)/raspberrypi.gpg] http://archive.raspberrypi.org/debian/ $RASPBIAN_VERSION main
EOF

sysroot="$(pwd)/sysroot"
mkdir -p "$sysroot"

tar -C "$sysroot" -xf toolchain.tar --exclude './dev'
rm toolchain.tar

# Copy only sysroot bits we need
mkdir -p "$RPI_ROOT" "$RPI_ROOT/usr" "$RPI_ROOT/usr/bin" \
	"$RPI_ROOT/usr/share" "$RPI_ROOT/opt/vc"
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
mv "$sysroot/usr/share/pkgconfig" "$RPI_ROOT/usr/share/"
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
