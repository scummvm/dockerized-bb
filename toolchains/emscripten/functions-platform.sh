do_configure () {
	source "$EMSDK/emsdk_env.sh" 
	emconfigure ./configure --prefix=$PREFIX --host=$HOST --disable-shared "$@"
}

do_cmake () {
	source "$EMSDK/emsdk_env.sh" 
	mkdir -p build
	cd build
	emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
	              -DBUILD_SHARED_LIBS=no "$@" ..
}

do_make () {
	source "$EMSDK/emsdk_env.sh" 
	emmake make "$@"
}
