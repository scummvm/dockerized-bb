do_configure () {
	emconfigure ./configure --prefix=$PREFIX --host=$HOST --disable-shared "$@"
}

do_cmake () {
	mkdir -p build
	cd build
	emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
	              -DBUILD_SHARED_LIBS=no "$@" ..
}

do_make () {
	emmake make "$@"
}
