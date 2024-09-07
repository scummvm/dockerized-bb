#! /bin/sh

#set -x
set -e

build_script=$1
shift 1

original_path=$PATH

if [ -z "$API" ]; then
	API=all
fi

TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}"

for c in ar c++filt nm objcopy objdump ranlib readelf strings strip; do
	v=$(echo $c | tr 'a-z+-' 'A-ZX_')
	export $v="$TOOLCHAIN/bin/llvm-$c"
done
export LD="$TOOLCHAIN/bin/lld"

for t in "$TOOLCHAIN/sysroot/usr/lib/"*/; do
	t=$(basename $t)
	if [ "$API" = "none" ]; then
		refined_apis='.'
	else
		lowest=$(basename "$(cd "$TOOLCHAIN/sysroot/usr/lib/$t" && ls -1d */ | head -n1)")
		if [ "$API" = "all" ]; then
			apis=$(cd "$TOOLCHAIN/sysroot/usr/lib/$t" && ls -1d */ | while read v; do echo -n "$(basename "$v") "; done)
		elif [ "$API" = "lowest" ]; then
			apis=$lowest
		else
			apis=$API
		fi

		refined_apis=
		for a in $apis; do
			# Try to find the best API version available like specified in Android docs
			while [ ! -d "$TOOLCHAIN/sysroot/usr/lib/$t/$a" ]; do
				# First, decrement
				if [ $a -le 0 ]; then
					break
				fi
				a=$(($a - 1))
			done
			if [ ! -d "$TOOLCHAIN/sysroot/usr/lib/$t/$a" ]; then
				# Still not found, lowest supported version by NDK
				a=$lowest
			fi
			refined_apis="$refined_apis\n$a"
		done
		refined_apis=$(echo $refined_apis | sort -u | tr '\n' ' ')
	fi

	for a in $refined_apis; do
		# Define all environment variables now that we have the target platform and API
		export HOST=$t TARGET=$t

		# Don't know why but libs and compiler don't have the same target prefix for ARM
		comp_target=$TARGET
		if [ $comp_target = "arm-linux-androideabi" ]; then
			comp_target=armv7a-linux-androideabi
		fi
		# Libvpx detects if AS ends with clang
		export AS=$TOOLCHAIN/bin/$comp_target$a-clang
		export CC=$TOOLCHAIN/bin/$comp_target$a-clang
		export CXX=$TOOLCHAIN/bin/$comp_target$a-clang++

		export PREFIX=$TOOLCHAIN/sysroot/usr
		export PATH=$original_path:$TOOLCHAIN/bin:$PREFIX/bin/$TARGET/$a
		export ACLOCAL_PATH=$PREFIX/share/aclocal
		export PKG_CONFIG_LIBDIR=$PREFIX/lib/$TARGET/$a/pkgconfig

		echo "Building for $TARGET-$a"

		API=$a $build_script "$@"
	done
done
