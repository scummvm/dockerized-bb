do_git_fetch () {
	if [ -d "$1"*/ ]; then
		rm -rf "$1"*/
	fi
	git clone "$2" "$1"
	cd "$1"*/
	git checkout "$3"
	git submodule update --init
	do_patch
}
