#! /bin/sh

TOOLCHAIN_VERSION=4d23381101e15cd53d9e1cb37e2a488d99d5b6e1
TARGETS="gcw0 rs90 lepus"

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch buildroot "https://github.com/OpenDingux/buildroot/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# Allow customizing build speed
sed -i -e 's/^nice ${NICEOPTS} make/nice make ${MAKEOPTS}/' rebuild.sh

num_cpus=$(nproc || grep -c ^processor /proc/cpuinfo || echo 1)
MAKEOPTS="-j${num_cpus}"
NICEOPTS="-n0"

# We will cleanup defconfig to have a small build just enough for us
WHITELIST=$(cat <<-"EOF"
	BUSYBOX.*
	FLAC
	FLUIDSYNTH
	MESA3D.*
	SDL
	SDL_KMSDRM
	SDL_NET
	SDL2
	SDL2_KMSDRM
	SDL2_OPENGLES
	SDL2_NET
	ALSA_LIB.*
	LIBMAD
	LIBVORBIS
	TREMOR
	FREETYPE
	JPEG
	LIBDRM
	LIBPNG
	TSLIB
	LIBTHEORA
	NCURSES.*
	READLINE
	UTIL_LINUX_LIBMOUNT
	LIBJPEG8
EOF
)

lighten() {
	local full orig target dest

	target=$1

	full=$(mktemp -d)
	config="configs/od_${target}_defconfig"

	# Create the standard config to know which libraries are really present in the full toolchain
	make "od_${target}_defconfig" BR2_EXTERNAL=board/opendingux O="$full"

	# Remove all packages
	sed -i '/^BR2_PACKAGE/d' "$config"
	# Disable ccache
	sed -i '/^BR2_CCACHE.*/d' "$config"
	# Remove some other settings
	sed -i '/^BR2_TARGET_ROOTFS_SQUASHFS=y/d' "$config"
	sed -i '/^BR2_ROOTFS_POST_IMAGE_SCRIPT=/d' "$config"

	# Add whitelisted packages which are already enabled
	echo "$WHITELIST" | while read pkg; do
		grep "^BR2_PACKAGE_$pkg=" "$full/.config" >> "$config" || true
	done

	# Disable now useless scripts
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|board/opendingux/[^/]\+/cleanup-rootfs.sh||' "$config"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|board/opendingux/create-modules-fs.sh||' "$config"
	# Remove all blanks
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s| \+| |g' "$config"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|=" *|="|' "$config"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s| *"$|"|' "$config"

	# Don't build a kernel, only headers
	sed -i 's/^BR2_LINUX_KERNEL=y$/# BR2_LINUX_KERNEL is not set/' "$config"
	echo "BR2_PACKAGE_LINUX_HEADERS=y" >> "$config"
	# Move kernel configuration to headers (not perfect but good enough)
	sed -i 's/^BR2_LINUX_KERNEL_/BR2_KERNEL_HEADERS_/' "$config"

	# Disable buildroot default settings
	echo '# BR2_PACKAGE_EUDEV_ENABLE_HWDB is not set' >> "$config"
	echo '# BR2_PACKAGE_URANDOM_SCRIPTS is not set' >> "$config"

	rm -rf "$full"
}

# Enable ccache for tools built with host gcc, this will speed up things a little
export CCACHE_DIR="$(pwd)/ccache"

mkdir -p ccache-bin
ln -s "$(which ccache)" ccache-bin/gcc
ln -s "$(which ccache)" ccache-bin/g++

export HOSTCC="$(pwd)/ccache-bin/gcc"
export HOSTCXX="$(pwd)/ccache-bin/g++"

mkdir -p "${OPENDINGUX_ROOT}/"
for target in $TARGETS; do

	# Lighten build process by removing useless packages for us
	lighten "$target"

	export CCACHE_BASEDIR=$(readlink -m "output/${target}")

	CONFIG=$target ./build.sh
	tar -C "${OPENDINGUX_ROOT}/" -xJf output/$target/images/opendingux-$target-toolchain.*.tar.xz
	"${OPENDINGUX_ROOT}/${target}-toolchain/relocate-sdk.sh"

	# Cleanup the build
	rm -rf output/$target
done

do_clean_bdir
