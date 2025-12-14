do_svn_fetch () {
	if [ -d "$1"*/ ]; then
		rm -rf "$1"*/
	fi
	svn co "$2" "$1"
	cd "$1"*/
	svn up $3
	do_patch
}

# Adapt paths for multilib
__do_configure_atari () {
	__do_configure --libdir=${PREFIX}/lib/${TARGET} --bindir=${PREFIX}/bin/${TARGET} "$@"
}

__do_cmake_atari () {
	__do_cmake \
		-DCMAKE_SYSTEM_NAME=Generic \
		-DCMAKE_SYSTEM_PROCESSOR=m68k \
		-DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib/${TARGET} \
		-DCMAKE_INSTALL_BINDIR=${PREFIX}/bin/${TARGET} \
		"$@"
}

for f in do_configure do_cmake; do
	unset -f $f
	eval "$f () { __${f}_atari \"\$@\"; }"
done
