do_svn_fetch () {
	if [ -d "$1"*/ ]; then
		rm -rf "$1"*/
	fi
	svn co "$2" "$1"
	cd "$1"*/
	do_patch
}
