FROM toolchains/common AS helpers
FROM toolchains/apple-sdks AS sdks
FROM toolchains/macosx-common AS macosx-common

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`helpers_package', helpers_package($1,$2,$3) && osxcross-macports fake-install $1 && rm -Rf ${TARGET_DIR}/macports/cache)m4_dnl
m4_define(`common_package', COPY --from=macosx-common /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`ports_package', RUN $3 osxcross-macports ``${MACOSX_PORTS_ARCH_ARG}'' -s install $1 $2 && rm -Rf ${TARGET_DIR}/macports/cache)m4_dnl

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

ENV TARGET_DIR=/opt/osxcross

m4_ifdef(`OSXCROSS_CLANG',
# Compile clang before anything else to reuse the result in all MacOSX toolchains
common_package(osxcross-clang)
, m4_ifdef(`PPA_CLANG',
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
, ```fatal_error(No clang version defined)''')))m4_dnl

ENV SDK_DIR=/opt/sdk

# Keep in sync with apple_sdks
COPY --from=sdks /sdk/MacOSX`'MACOSX_SDK_VERSION`'* ${SDK_DIR}/

common_package(osxcross)

# Use same prefix as in MacPorts and DESTDIR to install at correct place
# That way, we can use osxcross pkg-config wrapper even for our packages
ENV HOST=MACOSX_TARGET_ARCH-apple-darwin`'MACOSX_TARGET_VERSION \
	`MACOSX_DEPLOYMENT_TARGET'=MACOSX_DEPLOYMENT_TARGET \
	`MACOSX_PORTS_ARCH_ARG'=MACOSX_PORTS_ARCH_ARG \
	OSXCROSS_MACPORTS_MIRROR="http://packages.macports.org" \
	DESTDIR=${TARGET_DIR}/macports/pkgs \
	PREFIX=/opt/local

# We add PATH here for *-config and platform specific binaries
# We define PKG_CONFIG_SYSROOT_DIR to let pkg-config behave the same way when invoked without using wrapper
# We define OSXCROSS_MP_INC to have clang automatically add macports path
ENV \
	def_binaries(`${TARGET_DIR}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	CPP="${TARGET_DIR}/bin/${HOST}-cc -E" \
	CC=${TARGET_DIR}/bin/${HOST}-cc \
	CXX=${TARGET_DIR}/bin/${HOST}-c++ \
	CFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	CXXFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	LDFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	def_aclocal(`${TARGET_DIR}/macports/pkgs/${PREFIX}') \
	PKG_CONFIG_SYSROOT_DIR=${DESTDIR} \
	def_pkg_config(`${DESTDIR}/${PREFIX}') \
	PATH=$PATH:${TARGET_DIR}/bin:${TARGET_DIR}/SDK/MacOSX`'MACOSX_SDK_VERSION`'.sdk/usr/bin:${DESTDIR}/${PREFIX}/bin \
	OSXCROSS_MP_INC=1

# TODO: build won't be reproducible: we should stick to some version and compile it instead

# zlib is provided in SDK but libpng uses ports one
ports_package(zlib)

ports_package(bzip2)

ports_package(libpng)

ports_package(libjpeg-turbo)

ports_package(faad2)

ports_package(libmad)

ports_package(libtheora)

ports_package(libvorbis)

helpers_package(flac)

# mpeg2dec in ports comes with dependencies on X11 and SDL
# Even if Portfile can avoid it, that's not precompiled and osxcross only handles binary download
helpers_package(mpeg2dec)

ports_package(a52dec)

# No curl as it's provided in SDK

# Ports package is linked with brotli and fails to link statically because of
# different file names. Instead of patching, just build ourselves without brotli
helpers_package(freetype)

ports_package(fribidi)

# This is a shim package which uses ports but fixes paths in sdl2-config
common_package(libsdl2)

ports_package(libsdl2_net)

helpers_package(fluidsynth, -DCMAKE_SYSTEM_NAME=Darwin -DLIB_SUFFIX=)
