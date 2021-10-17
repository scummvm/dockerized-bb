__do_make_bdir () {
	# If build dir hasn't been cleant with do_clean_dir before this step will fail
	# It's intended to keep images size at minimum
	mkdir package-build
	cd package-build
	BUILD_DIR=$(pwd)
}

__do_clean_bdir () {
	[ -n "$BUILD_DIR" ] || error "BUILD_DIR not set"

	cd "$BUILD_DIR"/..
	rm -rf "$BUILD_DIR"
}

__do_patch () {
	local suffix
	if [ -n "$1" ]; then
		suffix="-$1"
	fi

	if [ -d "$PACKAGE_DIR/patches$suffix" ]; then
		for p in "$PACKAGE_DIR/patches$suffix"/*.patch; do
			echo "Applying $p"
			patch -t -p1 < "$p"
		done
	fi
}

# This function is a private helper and should not be unprefixed
__do_verify () {
	local hsh

	if [ -z "$2" ]; then
		# No verification method
		return
	fi

	case $2 in
		'gpgurl:'*)
			wget --no-hsts --progress=dot "${2#gpgurl:}" -O "$1.sig"
			if gpg --verify "$1.sig" "$1"; then
				return
			fi
			;;
		'sha1:'*)
			hsh=$(sha1sum "$1" |cut -f1 -d' ')
			if [ "$hsh" = "${2#sha1:}" ]; then
				return
			fi
			;;
		'sha256:'*)
			hsh=$(sha256sum "$1" |cut -f1 -d' ')
			if [ "$hsh" = "${2#sha256:}" ]; then
				return
			fi
			;;
		*)
			error "Verification method not supported: $2"
			;;
	esac

	error "BUG"
}

__do_pkg_fetch () {
	if [ -d "$1"*/ ]; then
		rm -rf "$1"*/
	fi
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get source -y "$1"
	rm -rf /var/lib/apt/lists/*
	cd "$1"*/
	do_patch
}

__do_http_fetch () {
	local fname
	if [ -d "$1"*/ ]; then
		rm -r "$1"*/
	fi
	fname=$(basename $2)
	wget --no-hsts --progress=dot "$2" -O "$fname"

	__do_verify "$fname" "$4"

	$3 "$fname"
	cd "$1"*/
	do_patch
}

__do_git_fetch () {
	if [ -d "$1"*/ ]; then
		rm -rf "$1"*/
	fi
	git clone "$2" "$1"
	cd "$1"*/
	git checkout "$3"
	git submodule update --init
	do_patch
}

__do_configure () {
	./configure --prefix=$PREFIX --host=$HOST --disable-shared "$@"
}

__do_cmake () {
	mkdir -p build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
		-DBUILD_SHARED_LIBS=no "$@" ..
}

__do_meson () {
	meson --prefix=$PREFIX --cross-file cross.ini --buildtype release --default-library static "$@" _build
	cd _build
}

__do_make () {
	local num_cpus
	num_cpus=$(nproc || grep -c ^processor /proc/cpuinfo || echo 1)
	make -j${NUM_CPUS:-$num_cpus} "$@"
}

__log () {
	echo "$@" >&2
}

__error () {
	log "$@"
	exit 1
}

# Create wrapper functions so that functions-platform.sh can override functions
# but still use base function (Poor man's inheritance)
# Aliases are expanded at definition time so that's not the good way
for f in do_make_bdir do_clean_bdir do_patch do_pkg_fetch do_http_fetch \
	do_git_fetch do_configure do_cmake do_meson do_make log error; do
	eval "$f () { __$f \"\$@\"; }"
done

if [ -z "$NO_FUNCTIONS_PLATFORM" -a -f "$HELPERS_DIR"/functions-platform.sh ]; then
	. "$HELPERS_DIR"/functions-platform.sh
fi

# Enable exit on error
set -e

# Enable commands trace
set -x
