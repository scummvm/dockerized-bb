#! /bin/sh

#set -x
set -e

get_cmake_variable () {
	grep "^set($1 \"" "$TOOLCHAIN/share/buildroot/toolchainfile.cmake" | sed -e 's/^set('"$1"' "\([^"]*\)" .*)$/\1/'
}

build_script=$1
shift 1

original_path=$PATH

for t in "$OPENDINGUX_ROOT/"*/; do

	export TOOLCHAIN=$t

	sysroot=$(ls -1d $t/*/sysroot)
	if ! [ -d "$sysroot" ]; then
		echo "Can't find sysroot in $t"
		exit 1
	fi

	export HOST=$(basename "$(dirname "$sysroot")")

	for c in ar as c++filt cc c++ ld nm objcopy objdump ranlib readelf strings strip; do
		v=$(echo $c | tr 'a-z+-' 'A-ZX_')
		export $v="$TOOLCHAIN/bin/$HOST-$c"
	done

	export PREFIX=$sysroot/usr
	export PATH=$original_path:$TOOLCHAIN/bin:$PREFIX/bin
	export ACLOCAL_PATH=$PREFIX/share/aclocal
	export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
	export PKG_CONFIG_SYSROOT_DIR=$sysroot

	export CFLAGS=$(get_cmake_variable CMAKE_C_FLAGS)
	export CXXFLAGS=$(get_cmake_variable CMAKE_CXX_FLAGS)
	export LDFLAGS=$(get_cmake_variable CMAKE_EXE_LINKER_FLAGS)

	echo "Building for $(basename "$t")"

	$build_script "$@"
done
