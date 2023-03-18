CMDLINE_TOOLS_VERSION=9477386
CMDLINE_TOOLS_CHECKSUM="sha256:bd1aa17c7ef10066949c88dc6c9c8d536be27f992a1f3b5a584f9bd2ba5646a0"
CMDLINE_TOOLS_SUBDIR=cmdline-tools

do_install_sdk_tools () {
	do_http_fetch "$CMDLINE_TOOLS_SUBDIR" \
		"https://dl.google.com/android/repository/commandlinetools-${HOST_TAG%%-*}-${CMDLINE_TOOLS_VERSION}_latest.zip" \
		'unzip' "${CMDLINE_TOOLS_CHECKSUM}"

	# Don't stay in tools subdirectory
	cd ..

	ANDROID_TEMP_SDK_DIR="$(pwd)"
	export ANDROID_SDK_HOME="$(pwd)"

	# Make sure we have the last version
	yes | "${ANDROID_TEMP_SDK_DIR}/${CMDLINE_TOOLS_SUBDIR}/bin/sdkmanager" --sdk_root="${ANDROID_TEMP_SDK_DIR}" --no_https --install "cmdline-tools;latest"
}

do_sdk_accept_licenses () {
	local dst=$1
	if [ -z "$dst" ]; then
		dst=${ANDROID_TEMP_SDK_DIR}
	fi

	yes | "${ANDROID_TEMP_SDK_DIR}/${CMDLINE_TOOLS_SUBDIR}/bin/sdkmanager" --sdk_root="$dst" --no_https --licenses >/dev/null
}

do_sdk_install () {
	local pkg=$1 dst=$2
	if [ -z "$dst" ]; then
		dst=${ANDROID_TEMP_SDK_DIR}
	fi

	# Install requested NDK
	yes | "${ANDROID_TEMP_SDK_DIR}/${CMDLINE_TOOLS_SUBDIR}/bin/sdkmanager" --sdk_root="$dst" --no_https --install "$pkg"
}
