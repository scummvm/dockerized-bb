do_lha_fetch () {
	local pkg_name
	pkg_name=$(basename $1)

	if [ -d "$pkg_name"/ ]; then
		rm -r "$pkg_name"/
	fi

	wget --no-hsts --progress=dot "http://os4depot.net/share/development/library/$1.lha" -O "$pkg_name.lha"

	__do_verify "$pkg_name.lha" "$3"

	mkdir "$pkg_name"
	cd "$pkg_name"

	lha x "../$pkg_name.lha"

	do_patch

	# No quotes to let globbing occur
	cd ./$2
}

do_lha_install () {
	local loc d lib srclib dstlib f gen_so dynamic

	if [ "$1" = "dynamic" ]; then
		dynamic=true
	else
		dynamic=
	fi

	for d in local Local; do
		if [ -d "$d" ]; then
			loc=$d
			break
		fi
	done
	if [ -z "$loc" ]; then
		error "Can't find Local directory"
	fi

	# Fix potentialy missing rights
	chmod -R go+rX $loc

	# When installing static, remove dynamic libraries
	if [ -z "$dynamic" ]; then
		for lib in newlib clib2; do
			if [ -d "$loc/$lib/lib" ]; then
				find "$loc/$lib/lib" '(' -name '*.so' -o -name '*.so.*' ')' -delete
			fi
		done
	fi

	# Common files like include
	for d in include; do
		if [ -d $loc/common/$d ]; then
			cp -R $loc/common/$d/. $DESTDIR/$PREFIX/$d/
		fi
	done

	# Files specific to libc used (newlib or clib2)
	for d in include lib; do
		if [ -d $loc/newlib/$d ]; then
			cp -R $loc/newlib/$d/. $DESTDIR/$PREFIX/$d/
		fi
		if [ -d $loc/clib2/$d -a -d $DESTDIR/$PREFIX/$d/clib2 ]; then
			cp -R $loc/clib2/$d/. $DESTDIR/$PREFIX/$d/clib2/
		fi
	done

	for lib in newlib clib2; do
		srclib=$loc/$lib/lib
		if [ "$lib" != "newlib" ]; then
			dstlib=$DESTDIR/$PREFIX/lib/$lib
		else
			dstlib=$DESTDIR/$PREFIX/lib
		fi

		if [ ! -d $srclib ]; then
			continue
		fi

		# Create symlink for .so
		for f in "$srclib"/*.so.*; do
			# If glob didn't match anything it will be used in the loop
			# Avoid it now
			if [ ! -e "$f" ]; then
				continue
			fi
			f=$(basename "$f")
			gen_so="${f%.so.*}.so"
			if [ -e "$dstlib/$gen_so" ]; then
				continue
			fi
			ln -sf "$f" "$dstlib/$gen_so"
		done

		# Fix pkg-config paths
		for f in "$srclib"/pkgconfig/*.pc; do
			# If glob didn't match anything it will be used in the loop
			# Avoid it now
			if [ ! -e "$f" ]; then
				continue
			fi
			f=$(basename "$f")
			sed -i -e "s#^prefix=.*\$#prefix=$PREFIX#" "$dstlib/pkgconfig/$f"
			sed -i -e "s#^exec_prefix=.*\$#exec_prefix=$PREFIX#" "$dstlib/pkgconfig/$f"
			sed -i -e 's#^libdir=.*$#libdir=${pcfiledir}/..#' "$dstlib/pkgconfig/$f"
			sed -i -e 's#^includedir=.*/include#includedir=${prefix}/include#' "$dstlib/pkgconfig/$f"
		done
	done

	# Install and fix config files the best we can
	for f in $loc/newlib/bin/*-config; do
		if [ ! -e "$f" ]; then
			continue
		fi
		if ! head -n1 $f | grep -q '^#![ ]*/bin/sh'; then
			continue
		fi
		cp $f $DESTDIR/$PREFIX/bin/
		f="$DESTDIR/$PREFIX/bin/$(basename "$f")"
		sed -i -e "s#^[ \\t]*prefix=.*\$#prefix=\"$PREFIX\"#" "$f"
		sed -i -e 's#^[ \t]*exec_prefix=.*$#exec_prefix="${prefix}"#' "$f"
		sed -i -e 's#^[ \t]*libdir=.*$#libdir="${prefix}/lib"#' "$f"
		sed -i -e 's#^[ \t]*includedir=\("\?\).*/include#includedir=\1${prefix}/include#' "$f"
		chmod +x "$f"
	done

}
