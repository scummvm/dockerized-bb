do_configure_shared () {
	./configure --prefix=$PREFIX --host=$HOST --enable-shared --disable-static "$@"
}
