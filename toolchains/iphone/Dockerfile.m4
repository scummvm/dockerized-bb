FROM toolchains/common AS helpers
FROM toolchains/apple-sdks AS sdks

m4_define(`PPA_CLANG',-10)m4_dnl
m4_define(`IPHONE_SDK_VERSION',14.0)m4_dnl
m4_define(`IPHONEOS_DEPLOYMENT_TARGET',7.0)m4_dnl

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		libbz2-dev \
		liblzma-dev \
		libxml2-dev \
		libssl-dev \
		python \
		uuid-dev \
		zlib1g-dev \
		&& \
	rm -rf /var/lib/apt/lists/*

ENV TARGET_DIR=/opt/iphone

m4_ifdef(`PPA_CLANG',
RUN . /etc/os-release && \
	echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME`'PPA_CLANG`' main" > /etc/apt/sources.list.d/clang.list && \
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'PPA_CLANG`' \
		llvm`'PPA_CLANG`'-dev \
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
	rm -rf /var/lib/apt/lists/*
, ``fatal_error(No clang version defined)''))m4_dnl

ENV SDK_DIR=/opt/sdk

# Keep in sync with apple_sdks
COPY --from=sdks /sdk/iPhoneOS`'IPHONE_SDK_VERSION`'* ${SDK_DIR}/

ENV `IPHONEOS_DEPLOYMENT_TARGET'=IPHONEOS_DEPLOYMENT_TARGET

# xar is an optional dependency of cctools_port to handle bitcode
local_package(xar)

local_package(toolchain)

# GAS preprocessor to have ARM assembly in libjpeg-turbo
local_package(gas-preprocessor)

ENV HOST=arm-apple-darwin11 \
	PREFIX=${TARGET_DIR}/SDK/iPhoneOS`'IPHONE_SDK_VERSION`'.sdk/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${TARGET_DIR}/bin/${HOST}-', `ar, as, ld, lipo, nm, ranlib, strings, strip') \
	CPP="${TARGET_DIR}/bin/${HOST}-clang -E" \
	CC=${TARGET_DIR}/bin/${HOST}-clang \
	CXX=${TARGET_DIR}/bin/${HOST}-clang++ \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${TARGET_DIR}/bin:${PREFIX}/bin

# To have LLVM builtins
local_package(compiler-rt)

# zlib is provided in SDK

# Needed for freetype (at least that's what ScummVM thinks)
helpers_package(bzip2)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, --with-simd, CCASFLAGS="-fno-integrated-as $CFLAGS")

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbis)

helpers_package(flac)

# Don't enable assembly part: it doesn't build
COPY ./packages/mpeg2dec lib-helpers/packages/mpeg2dec
helpers_package(mpeg2dec)

helpers_package(a52dec)

# Force -miphoneos-version-min as it gets added by curl if not already defined
# In this case curl uses 10.8
# Force DarwinSSL even if /System/Library/Frameworks/Security.framework doesn't exist
# Undo patch by Debian which makes use of specific linker flags
COPY ./packages/curl lib-helpers/packages/curl
helpers_package(curl, --without-ssl --with-darwinssl, CFLAGS="-miphoneos-version-min=IPHONEOS_DEPLOYMENT_TARGET")

helpers_package(freetype)

helpers_package(fribidi)

# Don't depend on SDL2 (paradoxical)
COPY ./packages/libsdl2-net lib-helpers/packages/libsdl2-net
helpers_package(libsdl2-net)

# intl doesn't get linked with CoreFoundation in glib, force it here
helpers_package(fluidsynth, -DCMAKE_SYSTEM_NAME=Darwin -DLIB_SUFFIX=, LDFLAGS="-framework CoreFoundation")
