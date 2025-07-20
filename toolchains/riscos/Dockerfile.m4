m4_include(`paths.m4')m4_dnl
m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY multi-build.sh functions-platform.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		autogen \
		m4 \
		texinfo \
		gcc \
		g++ \
		bison \
		flex \
		subversion \
		bash \
		gperf \
		sed \
		make \
		libtool \
		patch \
		wget \
		help2man \
		git \
		pandoc && \
	rm -rf /var/lib/apt/lists/*

ENV GCCSDK_INSTALL_CROSSBIN=/usr/local/gccsdk/cross/bin
ENV GCCSDK_INSTALL_ENV=/usr/local/gccsdk/env

local_sdk_package(toolchain)

local_sdk_package(iconv)

local_sdk_package(bindhelp)

local_sdk_package(tokenize)

local_sdk_package(zip)

local_sdk_package(makerun)

ENV PREFIX=${GCCSDK_INSTALL_ENV} HOST=arm-unknown-riscos

# Put GCCSDK_INSTALL_CROSSBIN before PATH because it overrides some binaries like zip
ENV \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `gcc, cpp, c++') \
	CC="${GCCSDK_INSTALL_CROSSBIN}/${HOST}-gcc" \
	PATH="${GCCSDK_INSTALL_CROSSBIN}:${PATH}" \
	CFLAGS_STD="-O3" \
	CXXFLAGS_STD="-O3" \
	ASFLAGS_VFP="-mfpu=vfp" \
	CFLAGS_VFP="-mfpu=vfp -O3" \
	CXXFLAGS_VFP="-mfpu=vfp -O3" \
	LDFLAGS_VFP="-mfpu=vfp"

helpers_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, -DCMAKE_TOOLCHAIN_FILE="${GCCSDK_INSTALL_ENV}/toolchain-riscos.cmake" -DCMAKE_SYSTEM_PROCESSOR=arm -DWITH_SIMD=0)

helpers_package(giflib)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libvorbisidec)

helpers_package(libtheora)

# Remove POSIX.1-2008 code which is incomplete (no utimensat)
COPY packages/flac lib-helpers/packages/flac
helpers_package(flac, --with-pic=no)

helpers_package(libmikmod)

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libmpcdec)

helpers_package(libvpx)

# helpers_package(openssl)

# helpers_package(curl)

helpers_package(fluidlite, -DCMAKE_TOOLCHAIN_FILE=$GCCSDK_INSTALL_ENV/toolchain-riscos.cmake)

helpers_package(freetype)

helpers_package(fribidi)

helpers_package(libsdl1.2)

# helpers_package(sdl-net1.2)

m4_define(`define_riscos_aliases', `define_aliases(
$1, riscosdist, --enable-plugins --default-dynamic, \
CFLAGS=\"-isysroot ${PREFIX}/$2include \${CFLAGS} \${CFLAGS_$3}\" \
CPPFLAGS=\"-isysroot ${PREFIX}/$2include \${CPPFLAGS} \${CPPFLAGS_$3}\" \
CXXFLAGS=\"-isysroot ${PREFIX}/$2include \${CXXFLAGS} \${CXXFLAGS_$3}\" \
LDFLAGS=\"-isysroot ${PREFIX}/$2lib \${LDFLAGS} \${LDFLAGS_$3}\" \
PKG_CONFIG_LIBDIR=${PREFIX}/$2lib/pkgconfig`'m4_ifelse(m4_eval($# > 3), 1, `, '$4,))')m4_dnl
define_riscos_aliases(arm-unknown-riscos, , STD)
define_riscos_aliases(arm-vfp-riscos, vfp/, VFP, vfp)
