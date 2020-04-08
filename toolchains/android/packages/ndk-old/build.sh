#! /bin/sh
NDK_VERSION=14b
NDK_SHA1=becd161da6ed9a823e25be5c02955d9cbca1dbeb

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..

# Don't load functions-platform.sh as it's not needed
NO_FUNCTIONS_PLATFORM=yes

. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch android-ndk "https://dl.google.com/android/repository/android-ndk-r${NDK_VERSION}-${HOST_TAG}.zip" 'unzip' \
	"sha1:${NDK_SHA1}"

# SDL2 can't compile with this version of NDK because of https://github.com/android/ndk/issues/370
# Patch include files
find . -path '*/usr/include/android/sensor.h' -exec sed -ie '/^#include <sys\/types.h>$/i #include <stdbool.h>' '{}' +

# What we do now is like Frankenstein, we make a unified toolchain from parts of toolchains not inteded to be unified.
# It's not perfect (GCC don't work) but it works when compiling ScummVM, so who cares?

mkdir -p "${ANDROID_NDK_ROOT}/"
# mv is faster than cp
mv ./* "${ANDROID_NDK_ROOT}/"

mkdir -p "${TOOLCHAIN}/"

for t in ${ABIS}; do
	arch=${t%/*}
	api=${t##*/}
	echo "Installing ${arch} with API ${api}"

	"${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py" --arch "${arch}" --api "${api}" --install-dir toolchain-temp --unified-headers

	triple=$(ls toolchain-temp/bin/*-clang| sed -n -e 's#^.*/\([^/]\+\)-clang$#\1#p')
	echo "Using triple ${triple}"

	libdir=toolchain-temp/sysroot/usr/lib64
	if [ ! -d "${libdir}" ]; then
		libdir=toolchain-temp/sysroot/usr/lib
	fi

	# Copy the whole toolchain
	cp -Rf toolchain-temp/. "${TOOLCHAIN}/"

	# Remove parts which are arch specific
	rm -Rf "${TOOLCHAIN}"/sysroot/usr/lib64 "${TOOLCHAIN}"/sysroot/usr/lib
	rm -Rf "${TOOLCHAIN}"/sysroot/usr/include/asm
	rm -Rf "${TOOLCHAIN}"/sysroot/usr/include/machine
	rm -Rf "${TOOLCHAIN}"/bin/clang "${TOOLCHAIN}"/bin/clang++
	# Remove GCC as it's unsupported
	rm -Rf "${TOOLCHAIN}"/bin/${triple}-gcc "${TOOLCHAIN}"/bin/${triple}-g++

	# Copy back arch specific missing parts to their right place
	# We use a temporary directory to not be picky when erasing above
	mkdir -p "${TOOLCHAIN}/sysroot/usr/.lib/${triple}"
	cp -Rf "${libdir}"/. "${TOOLCHAIN}/sysroot/usr/.lib/${triple}"

	# Don't repeat over and over this, needs to be escaped, part
	sysroot_path='`dirname $0`/../sysroot'
	# Patch include search path to add arch specific directory
	for f in "${TOOLCHAIN}"/bin/${triple}-clang "${TOOLCHAIN}"/bin/${triple}-clang++; do
		sed -i -e "2 r /dev/stdin" \
			-e "s#--sysroot#-B=/usr/lib/${triple} \"\$linker\" -idirafter ${sysroot_path}/usr/include/${triple} &#" \
			"$f" <<EOF
    linker="-Wl,-L${sysroot_path}/usr/lib/${triple}"
    for a in "\$@"; do
		if [ "\$a" == "-E" -o "\$a" == "-S" -o "\$a" == "-c" -o "\$a" == "-fsyntax-only" ]; then
			linker=""
			break
		fi
    done
EOF
	done
	rm -Rf toolchain-temp
done

# NDK install bogus libstdc++ in sysroot, remove them
find "${TOOLCHAIN}/sysroot/usr/.lib" '(' -name libstdc++.a -o -name libstdc++.so ')' -delete

# Move libs back where they should be
mv "${TOOLCHAIN}/sysroot/usr/.lib" "${TOOLCHAIN}/sysroot/usr/lib"

do_clean_bdir
