# Paths are not standard in Android toolchain, adapt them
__do_configure_android () {
	if [ "${API}" = "." ]; then
		__do_configure --libdir=${PREFIX}/lib/${TARGET} --bindir=${PREFIX}/bin/${TARGET} "$@"
	else
		__do_configure --libdir=${PREFIX}/lib/${TARGET}/${API} \
			--bindir=${PREFIX}/bin/${TARGET}/${API} "$@"
	fi
}

__do_cmake_android () {
	local cmake_target cmake_args orig_api
	orig_api=${API}
	if [ "${API}" = "." ]; then
		API=$(sed -ne 's/^.*-D__ANDROID_API__=\([0-9]\+\) .*$/\1/p' "$CC")
		cmake_args="-DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang"
	fi
	case $TARGET in
		arm-linux-androideabi) cmake_target=armeabi-v7a ;;
		aarch64-linux-android) cmake_target=arm64-v8a ;;
		i686-linux-android) cmake_target=x86 ;;
		x86_64-linux-android) cmake_target=x86_64 ;;
		*) error "Unknown target ${TARGET}" ;;
	esac
	__do_cmake -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=${cmake_target} \
		-DANDROID_NATIVE_API_LEVEL=${API} \
		-DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib/${TARGET}/${orig_api} \
		-DCMAKE_INSTALL_BINDIR=${PREFIX}/bin/${TARGET}/${orig_api} \
		$cmake_args \
		"$@"
}

for f in do_configure do_cmake; do
	unset -f $f
	eval "$f () { __${f}_android \"\$@\"; }"
done
