#! /bin/sh

# Inspired by excellent tpoechtrager/osxcross build_compiler_rt.sh
# It sadly works only for MacOSX

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

SDK_DIR=$(readlink -e $PREFIX/..)
SDK_VERSION=$(basename "${SDK_DIR}" | sed -e 's/^[A-Za-z]\+\([0-9.]\+\)\.sdk$/\1/')

CLANG_VERSION=$(echo "__clang_major__ __clang_minor__ __clang_patchlevel__" | \
	 $CC -E - | tail -n1 | tr ' ' '.')

CLANG_LIB_DIR=$($CC -print-search-dirs | grep "libraries: =" | \
	                tr '=' ' ' | tr ':' ' ' | awk '{print $2}')

CLANG_INCLUDE_DIR="${CLANG_LIB_DIR}/include"
CLANG_DARWIN_LIB_DIR="${CLANG_LIB_DIR}/lib/darwin"

# Don't support below 4.x and master to simplify
#CLANG_MAJOR=${CLANG_VERSION%%.*}
#BRANCH=release/$CLANG_MAJOR.x
#do_git_fetch llvm-project "https://github.com/llvm/llvm-project.git" "${BRANCH}"
#cd compiler-rt

CLANG_MAJOR=$(echo ${CLANG_VERSION} | cut -d. -f1)
CLANG_MINOR=$(echo ${CLANG_VERSION} | cut -d. -f2)
CLANG_PATCH=$(echo ${CLANG_VERSION} | cut -d. -f3)
# --spider doesn't work with Github/AWS so just do a 1 byte download to /dev/null
while ! wget --header='Range: bytes=0-0' -O /dev/null \
	"https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/compiler-rt-${CLANG_VERSION}.src.tar.xz"; do
	if [ "$CLANG_PATCH" -eq 0 ]; then
		if [ "$CLANG_MINOR" -eq 0 ]; then
			exit 1
		fi
		CLANG_MINOR=$(($CLANG_MINOR - 1))
		# llvm didn't went above 3 in patch version
		CLANG_PATCH=10
	fi
	CLANG_PATCH=$(($CLANG_PATCH - 1))
	CLANG_VERSION=${CLANG_MAJOR}.${CLANG_MINOR}.${CLANG_PATCH}
done

do_http_fetch compiler-rt "https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/compiler-rt-${CLANG_VERSION}.src.tar.xz" 'tar xJf'

# We try to support as much versions as we can so fallback on a common ground and fix it
#sed -i 's/COMMAND xcodebuild -version -sdk \${sdk_name}.internal Path/'\
#'COMMAND xcrun --sdk ${sdk_name}.internal --show-sdk-path/g' \
#	cmake/Modules/CompilerRTDarwinUtils.cmake
#sed -i 's/COMMAND xcodebuild -version -sdk \${sdk_name} Path/'\
#'COMMAND xcrun --sdk ${sdk_name} --show-sdk-path/g' \
#	cmake/Modules/CompilerRTDarwinUtils.cmake
#sed -i 's/COMMAND xcodebuild -version -sdk \${sdk_name}\.internal SDKVersion/'\
#'COMMAND xcrun --sdk ${sdk_name}.internal --show-sdk-version/g' \
#	cmake/Modules/CompilerRTDarwinUtils.cmake
#sed -i 's/COMMAND xcodebuild -version -sdk \${sdk_name}\.internal SDKVersion/'\
#'COMMAND xcrun --sdk ${sdk_name} --show-sdk-version/g' \
#	cmake/Modules/CompilerRTDarwinUtils.cmake
#
#sed -i 's|COMMAND xcrun --sdk \${sdk_name}\..* --show-sdk-path|'\
#"COMMAND echo \"$SDK_DIR\"|g" \
#	cmake/Modules/CompilerRTDarwinUtils.cmake
#sed -i 's|COMMAND xcrun --sdk \${sdk_name}\..* --show-sdk-version|'\
#"COMMAND echo \"$SDK_VERSION\"|g" \
#	cmake/Modules/CompilerRTDarwinUtils.cmake

if ! grep -qF 'DARWIN_${sdk_name}_OVERRIDE_SDK_VERSION' cmake/Modules/CompilerRTDarwinUtils.cmake; then
	# Add override version if not already available
	sed -i '/function(find_darwin_sdk_version var sdk_name)/a if (DARWIN_${sdk_name}_OVERRIDE_SDK_VERSION)\n'\
'message(WARNING "Overriding ${sdk_name} SDK version to ${DARWIN_${sdk_name}_OVERRIDE_SDK_VERSION}")\n'\
'set(${var} "${DARWIN_${sdk_name}_OVERRIDE_SDK_VERSION}" PARENT_SCOPE)\n'\
'return()\n'\
'endif()' cmake/Modules/CompilerRTDarwinUtils.cmake
fi

# Don't build for osx
sed -i 's/set(BUILTIN_SUPPORTED_OS .*)$/set(BUILTIN_SUPPORTED_OS )/' cmake/builtin-config-ix.cmake

# Build for tvOS
sed -i 's/option(COMPILER_RT_ENABLE_TVOS "Enable building for tvOS - Experimental" Off)$/option(COMPILER_RT_ENABLE_TVOS "Enable building for tvOS - Experimental" On)/' cmake/base-config-ix.cmake

# Fix paths
sed -i "s|COMMAND lipo |COMMAND $LIPO |g" \
	cmake/Modules/CompilerRTDarwinUtils.cmake
sed -i "s|COMMAND ld |COMMAND $LD |g" \
	cmake/Modules/CompilerRTDarwinUtils.cmake
sed -i "s|COMMAND codesign |COMMAND true |g" \
	cmake/Modules/AddCompilerRT.cmake
sed -i 's|${CMAKE_COMMAND} -E ${COMPILER_RT_LINK_OR_COPY}|ln -sf|g' \
	lib/builtins/CMakeLists.txt
if [ -f lib/orc/CMakeLists.txt ]; then
	sed -i 's|list(APPEND ORC_CFLAGS -I${DIR})||g' \
		lib/orc/CMakeLists.txt
fi

# Use raw clang/clang++ as the build system already adds parameters
# Override MacOSX version as we don't have any SDK for it
# Only build built-ins, sanitizers don't work on tvOS anyway
do_cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_SYSTEM_NAME=Darwin \
	-DCMAKE_LIPO=$LIPO \
	-DCMAKE_OSX_SYSROOT="$SDK_DIR" \
	-DDARWIN_macosx_OVERRIDE_SDK_VERSION=99.99 \
        -DDARWIN_appletvos_CACHED_SYSROOT="$SDK_DIR" \
	-DCOMPILER_RT_BUILD_BUILTINS=ON \
	-DCOMPILER_RT_BUILD_SANITIZERS=OFF \
	-DCOMPILER_RT_BUILD_XRAY=OFF \
	-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
	-DCOMPILER_RT_BUILD_PROFILE=OFF \
	-DCOMPILER_RT_BUILD_MEMPROF=OFF \
	-DCOMPILER_RT_BUILD_ORC=OFF \
	-DCOMPILER_RT_BUILD_GWP_ASAN=OFF

do_make

# Copy in a known place for worker
mkdir -p "${TARGET_DIR}/compiler-rt/${CLANG_INCLUDE_DIR}"
mkdir -p "${TARGET_DIR}/compiler-rt/${CLANG_DARWIN_LIB_DIR}"
cp -rv ../include/sanitizer "${TARGET_DIR}/compiler-rt/${CLANG_INCLUDE_DIR}"
cp lib/darwin/*.a "${TARGET_DIR}/compiler-rt/${CLANG_DARWIN_LIB_DIR}"

# Install in-tree
mkdir -p "${CLANG_INCLUDE_DIR}"
mkdir -p "$(dirname "${CLANG_DARWIN_LIB_DIR}")"

rm -rf "${CLANG_INCLUDE_DIR}/sanitizer"
ln -s "${TARGET_DIR}/compiler-rt/${CLANG_INCLUDE_DIR}/sanitizer" "${CLANG_INCLUDE_DIR}"

ln -s "${TARGET_DIR}/compiler-rt/${CLANG_DARWIN_LIB_DIR}" "${CLANG_DARWIN_LIB_DIR}"

do_clean_bdir
