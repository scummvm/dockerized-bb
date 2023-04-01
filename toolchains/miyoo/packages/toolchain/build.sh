#! /bin/sh

# This version depends on Miyoo devel package
BUILDROOT_VERSION=2018.02.9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch buildroot- "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz" 'tar xzf'
do_patch buildroot

num_cpus=$(nproc || grep -c ^processor /proc/cpuinfo || echo 1)
MAKEOPTS="-j${num_cpus}"

# We will cleanup defconfig to have a small build just enough for us
WHITELIST=$(cat <<-"EOF"
	UCLIBC
	BUSYBOX.*
	BZIP2
	GETTEXT
	MESA3D.*
	SDL
	SDL_FBCON
	SDL_NET
	SDL2
	SDL2_X11
	SDL2_NET
	XORG7
	XLIB_.*
	ALSA_LIB.*
	LIBMAD
	LIBVORBIS
	TREMOR
	FREETYPE
	GIFLIB
	JPEG
	LIBDRM.*
	LIBGLU
	LIBPNG
	TSLIB
	LIBTHEORA
	LIBCURL
	LIBFRIBIDI
	LIBICONV
	NCURSES.*
	READLINE
	LIBJPEG
EOF
)

lighten() {
	# Update configuration
	make olddefconfig

	# Backup our full configuration
	cp .config .config.full

	# Build in our build directory
	sed -i '/^BR2_HOST_DIR=.*/d' ".config"

	# Remove all packages
	sed -i '/^BR2_PACKAGE/d' ".config"
	# Remove some other settings
	sed -i 's/^BR2_TARGET_ROOTFS_TAR=y$/# BR2_TARGET_ROOTFS_TAR is not set/' ".config"
	sed -i 's/^BR2_PACKAGE_HOST_PATCHELF=y$/# BR2_PACKAGE_HOST_PATCHELF is not set/' ".config"

	# Add whitelisted packages which are already enabled
	echo "$WHITELIST" | while read pkg; do
		grep "^BR2_PACKAGE_$pkg=" ".config.full" >> ".config" || true
	done

	# It seems that the config file hasn't these enabled while the toolchain has
	echo "BR2_PACKAGE_FLAC=y" >> ".config"
	echo "BR2_PACKAGE_NCURSES_WCHAR=y" >> ".config"

	# Fixup everything
	make olddefconfig
}

cp ${PACKAGE_DIR}/config_buildroot-${BUILDROOT_VERSION} .config

# Lighten build process by removing useless packages for us
lighten

FORCE_UNSAFE_CONFIGURE=1 make sdk

mkdir -p "$(basename "${MIYOO_ROOT}")"
mv output/host "${MIYOO_ROOT}"

cp .config "${MIYOO_ROOT}"/

"${MIYOO_ROOT}/relocate-sdk.sh"

# Cleanup the build
rm -rf output

do_clean_bdir
