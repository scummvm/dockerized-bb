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

mkdir -p "${OPENDINGUX_ROOT}/"
for target in $TARGETS; do

	# Lighten build process by removing useless packages for us
	for conf in BR2_PACKAGE_HOST_GDB BR2_PACKAGE_VALGRIND BR2_PACKAGE_GDB BR2_PACKAGE_GDB_SERVER BR2_PACKAGE_GDB_DEBUGGER \
		BR2_PACKAGE_STRACE BR2_PACKAGE_STRESS BR2_PACKAGE_APITRACE; do
		sed -i -e "s/^${conf}=.*$/# ${conf} is not set/" configs/od_${target}_defconfig
	done

	CONFIG=$target ./rebuild.sh
	tar -C "${OPENDINGUX_ROOT}/" -xJf output/$target/images/opendingux-$target-toolchain.*.tar.xz
	"${OPENDINGUX_ROOT}/${target}-toolchain/relocate-sdk.sh"

	# Cleanup the build
	rm -rf output/$target
done

do_clean_bdir
