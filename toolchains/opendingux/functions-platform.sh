do_configure_shared () {
	./configure --prefix=$PREFIX --host=$HOST "$@"
}
