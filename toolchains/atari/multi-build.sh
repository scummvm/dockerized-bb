#! /bin/sh
# Simple helper script which builds for Atari ST and Firebee

#set -x
set -e

targets=$1
shift 1
build_script=$1
shift 1

VARS="ASFLAGS CFLAGS CXXFLAGS LDFLAGS"

for var in $VARS; do
	eval "${var}_BACKUP=\${${var}}"
done

setup_env () {
	local var suffix

	suffix=$(echo "$TARGET" | tr 'a-z+-' 'A-ZX_')

	for var in $VARS; do
		eval "export ${var}=\"\${CPUFLAG_${suffix}} \${${var}_BACKUP}\""
	done

	export LIBDIR="${PREFIX}/lib/${TARGET}"
	export PKG_CONFIG_LIBDIR="${LIBDIR}/pkgconfig"
}

for target in $targets; do
	echo "Building for $target"
	export TARGET="$target"
	setup_env
	"$build_script" "$@"
done
