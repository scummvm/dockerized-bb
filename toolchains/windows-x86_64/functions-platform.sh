__do_make_bdir_win () {
	__do_make_bdir "$@"

	# As mingw toolchain is mixed with debian binary packages
	# Create a temporary dir where everything will be put and symlink from there
	export DESTDIR="$BUILD_DIR/destdir"
	mkdir -p "$BUILD_DIR/destdir"
	mkdir -p /toolchain
}

__do_clean_bdir_win () {
	local d f

	[ -n "$BUILD_DIR" ] || error "BUILD_DIR not set"

	# Copy DESTDIR to permanent place
	cp -a "$DESTDIR"/. /toolchain

	# Replicate newly created tree
	{ cd "$DESTDIR"; find -type d; } | while read d; do mkdir -p "/$d"; done
	{ cd "$DESTDIR"; find -type f; } | while read f; do ln -nsf "$(readlink -e "/toolchain/$f")" "/$f"; done

	__do_clean_bdir "$@"
}

for f in do_make_bdir do_clean_bdir; do
	unset -f $f
	eval "$f () { __${f}_win \"\$@\"; }"
done
