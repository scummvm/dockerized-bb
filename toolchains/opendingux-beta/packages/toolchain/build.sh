#! /bin/sh

# We use a date like the filename in officially released toolchains, we don't have more
TOOLCHAIN_VERSION=2021-10-22
TARGETS="gcw0 rs90 lepus"

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch opendingux https://github.com/OpenDingux/buildroot.git opendingux
git checkout `git rev-list -n 1 --first-parent --before="$TOOLCHAIN_VERSION 23:59" opendingux`

# Use a suffixed directory to avoid automatic patching at fetching stage
do_patch od

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
	orig=$(mktemp)
	dest="configs/od_${target}_defconfig"

	# Create the standard config to know which libraries are really present in the full toolchain
	make "od_${target}_defconfig" BR2_EXTERNAL=board/opendingux O="$full"

	cp "$dest" "$orig"

	# Remove all packages
	grep -v '^BR2_PACKAGE' "$orig" > "$dest"
	# Remove some other settings
	sed -i '/^BR2_TARGET_ROOTFS_SQUASHFS=y/d' "$dest"

	# Add whitelisted packages which are already enabled
	echo "$WHITELIST" | while read pkg; do
		grep "^BR2_PACKAGE_$pkg=" "$full/.config" >> "$dest" || true
	done

	# Disable now useless scripts
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|board/opendingux/[^/]\+/cleanup-rootfs.sh||' "$dest"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|board/opendingux/create-modules-fs.sh||' "$dest"
	# Remove all blanks
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s| \+| |g' "$dest"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s|=" *|="|' "$dest"
	sed -i '/^BR2_ROOTFS_POST_BUILD_SCRIPT=/s| *"$|"|' "$dest"

	# Don't build a kernel, only headers
	sed -i 's/^BR2_LINUX_KERNEL=y$/# BR2_LINUX_KERNEL is not set/' "$dest"
	echo "BR2_PACKAGE_LINUX_HEADERS=y" >> "$dest"
	# Move kernel configuration to headers (not perfect but good enough)
	sed -i 's/^BR2_LINUX_KERNEL_/BR2_KERNEL_HEADERS_/' "$dest"

	# Disable buildroot default settings
	echo '# BR2_PACKAGE_EUDEV_ENABLE_HWDB is not set' >> "$dest"
	echo '# BR2_PACKAGE_URANDOM_SCRIPTS is not set' >> "$dest"

	# Enable ccache (this will help a little between targets)
	echo 'BR2_CCACHE=y' >> "$dest"
	echo 'BR2_CCACHE_DIR="$(TOPDIR)/ccache"' >> "$dest"

	rm "$orig"
	rm -rf "$full"
}

mkdir -p "${OPENDINGUX_ROOT}/"
for target in $TARGETS; do

	# Lighten build process by removing useless packages for us
	lighten "$target"

	CONFIG=$target ./rebuild.sh
	tar -C "${OPENDINGUX_ROOT}/" -xJf output/$target/images/opendingux-$target-toolchain.*.tar.xz
	"${OPENDINGUX_ROOT}/${target}-toolchain/relocate-sdk.sh"

	# Cleanup the build
	rm -rf output/$target
done

do_clean_bdir
