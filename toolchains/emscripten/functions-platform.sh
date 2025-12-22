__do_configure_emscripten () {
	emconfigure ./configure --prefix=$PREFIX --host=$HOST --disable-shared "$@"
}

__do_cmake_emscripten () {
	mkdir -p build
	cd build
	emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
	              -DBUILD_SHARED_LIBS=no "$@" ..
}

__do_make_emscripten () {
	emmake make "$@"
}

__setup_env() {
	local pwd
	if [ -f "$EMSDK/emsdk_env.sh" ]; then
		pwd=$(pwd)
		cd "$EMSDK"
		. "./emsdk_env.sh"
		cd "$pwd"
	fi
}

__setup_env
for f in do_configure do_cmake do_make; do
        unset -f $f
        eval "$f () { __${f}_emscripten \"\$@\"; }"
done
