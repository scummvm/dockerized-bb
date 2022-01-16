#! /bin/sh
# Simple helper script which builds with and without VFP

#set -x
set -e

build_script=$1
shift 1

VARS="ASFLAGS CPPFLAGS CFLAGS CXXFLAGS LDFLAGS PREFIX"

for var in $VARS; do
	eval "${var}_BACKUP=\${${var}}"
done

setup_env () {
	local mode var suffix

	mode=$1
	suffix=$2

	for var in $VARS; do
		eval "export ${var}=\"\${${var}_${mode}} \${${var}_BACKUP}\""
	done

	export PREFIX="${PREFIX_BACKUP}/${suffix}"
	export ACLOCAL_PATH="${PREFIX}/share/aclocal"
	export PKG_CONFIG_LIBDIR="${PREFIX}/lib/pkgconfig"

	export CPPFLAGS="-isystem ${PREFIX}/include ${CPPFLAGS}"
	export CFLAGS="-isystem ${PREFIX}/include ${CFLAGS}"
	export CXXFLAGS="-isystem ${PREFIX}/include ${CXXFLAGS}"
	export LDFLAGS="-L${PREFIX}/lib ${CFLAGS}"
	export LIBDIR="${PREFIX}/lib"
}

echo "Building for standard ARM"
setup_env STD ""
"$build_script" "$@"

echo "Building for VFP ARM"
setup_env VFP "vfp"
"$build_script" "$@"
