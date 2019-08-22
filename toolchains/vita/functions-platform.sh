do_vdpm_fetch () {
	if [ -d "$1" ]; then
		rm -r "$1"
	fi
	mkdir "$1"
	cd "$1"

	wget --progress=dot "http://dl.vitasdk.org/$1.tar.xz" -O - | tar --no-same-owner --no-same-permissions -xJ
	do_patch
}

do_vdpm_install () {
	cp -a . "$DESTDIR/$PREFIX/"
}
