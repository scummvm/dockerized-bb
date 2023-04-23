m4_dnl This script supports (i|tv)OS

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`common_package', COPY --from=apple-common /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
FROM toolchains/apple-sdks AS sdks
FROM toolchains/apple-common AS apple-common

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		libbz2-dev \
		liblzma-dev \
		libxml2-dev \
		libssl-dev \
		python3 \
		python3-setuptools \
		uuid-dev \
		zlib1g-dev \
		&& \
	rm -rf /var/lib/apt/lists/*

m4_ifdef(`PPA_CLANG',
RUN . /etc/os-release && \
	echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME`'PPA_CLANG`' main" > /etc/apt/sources.list.d/clang.list && \
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'PPA_CLANG`' \
		llvm`'PPA_CLANG`'-dev \
		libomp`'PPA_CLANG`'-dev \
		&& \
	rm -rf /var/lib/apt/lists/* && \
	rm /etc/apt/sources.list.d/clang.list /etc/apt/trusted.gpg

# Add newly installed LLVM to path
ENV PATH=$PATH:/usr/lib/llvm`'PPA_CLANG`'/bin
, m4_ifdef(`DEBIAN_CLANG',
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'DEBIAN_CLANG \
		llvm`'DEBIAN_CLANG`'-dev \
		&& \
	for f in /usr/lib/llvm`'DEBIAN_CLANG/bin/*; do ln -sf $f /usr/bin/$(basename $f); done && \
	rm -rf /var/lib/apt/lists/*
, ``fatal_error(No clang version defined)''))m4_dnl

# xar is an optional dependency of cctools_port to handle bitcode
common_package(xar)

ENV TARGET_DIR=/opt/toolchain

ENV SDK_DIR=/opt/sdk

# Keep in sync with apple_sdks
COPY --from=sdks /sdk/XOS_SDK_BASE`'XOS_SDK_VERSION`'* ${SDK_DIR}/

ENV m4_translit(XOS_PLATFORM, `a-z', `A-Z')`'OS_DEPLOYMENT_TARGET=XOS_DEPLOYMENT_TARGET

common_package(cctools-port, XOS_PLATFORM)

ENV HOST=aarch64-apple-darwin11 \
	PREFIX=${TARGET_DIR}/SDK/XOS_SDK_BASE`'XOS_SDK_VERSION`'.sdk/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${TARGET_DIR}/bin/${HOST}-', `ar, as, ld, lipo, nm, ranlib, strings, strip') \
	CPP="${TARGET_DIR}/bin/${HOST}-clang -E" \
	CC=${TARGET_DIR}/bin/${HOST}-clang \
	CXX=${TARGET_DIR}/bin/${HOST}-clang++ \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${TARGET_DIR}/bin:${PREFIX}/bin

# Without a platform file CMake fails some tests because variables are not passed to child invocations
# Using a toolchain file seems to fix it
COPY XOS_PLATFORM`'.platform ${TARGET_DIR}/

# Generate meson cross file for GLib
crossgen(darwin, aarch64)

# To have LLVM builtins
common_package(compiler-rt)

# zlib is provided in SDK

# Needed for freetype (at least that's what ScummVM thinks)
helpers_package(bzip2)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, -DCMAKE_TOOLCHAIN_FILE=${TARGET_DIR}/XOS_PLATFORM`'.platform)

helpers_package(giflib)

helpers_package(faad2)

# Fork is not supported in tvOS and not used in iOS
helpers_package(libmad, ac_cv_func_fork=no)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbis)

helpers_package(flac)

helpers_package(libmikmod)

# Don't enable assembly part: it doesn't build
COPY --from=apple-common /lib-helpers/packages/mpeg2dec lib-helpers/packages/mpeg2dec
helpers_package(mpeg2dec)

helpers_package(a52dec)

# libvpx thinks that darwin means xcode and adds too many flags
# disable this treatment
COPY --from=apple-common /lib-helpers/packages/libvpx lib-helpers/packages/libvpx
helpers_package(libvpx)

# Force -miphoneos-version-min as it gets added by curl if not already defined
# In this case curl uses 10.8, this behaviour has been removed in curl 7.76.1
# Undo patch by Debian which makes use of specific linker flags
# Disable NTLM since it requires fork which is not supported in tvOS
# This is never used anyway
COPY --from=apple-common /lib-helpers/packages/curl lib-helpers/packages/curl
helpers_package(curl, --without-ssl --with-secure-transport --disable-ntlm-wb, CFLAGS="-m`'XOS_PLATFORM`'os-version-min=XOS_DEPLOYMENT_TARGET")

helpers_package(freetype)

helpers_package(fribidi)

# Don't depend on SDL2 (paradoxical)
COPY --from=apple-common /lib-helpers/packages/libsdl2-net lib-helpers/packages/libsdl2-net
helpers_package(libsdl2-net)

# Lighten glib build by removing Objective C and Cocoa and fix intl detection
COPY --from=apple-common /lib-helpers/packages/fluidsynth lib-helpers/packages/fluidsynth
helpers_package(fluidsynth, -DCMAKE_SYSTEM_NAME=Darwin -DLIB_SUFFIX=)
