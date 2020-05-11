FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/
COPY functions-platform.sh lib-helpers/

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
		pandoc && \
	rm -rf /var/lib/apt/lists/*

ENV GCCSDK_INSTALL_CROSSBIN=/usr/local/gccsdk/cross/bin HOST=arm-unknown-riscos
ENV GCCSDK_INSTALL_ENV=/usr/local/gccsdk/env
ENV PREFIX=$GCCSDK_INSTALL_ENV

local_package(toolchain)

local_package(iconv)

local_package(bindhelp)

local_package(tokenize)

local_package(zip)

ENV \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `gcc, cpp, c++') \
	CC=$GCCSDK_INSTALL_CROSSBIN/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$GCCSDK_INSTALL_CROSSBIN:$PATH

helpers_package(zlib)

helpers_package(libpng1.6, , CPPFLAGS="$CPPFLAGS -I$PREFIX/include" LDFLAGS="$LDFLAGS -L$PREFIX/lib")

helpers_package(libjpeg-turbo)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libvorbisidec)

helpers_package(libtheora)

helpers_package(flac, --with-pic=no)

helpers_package(faad2)

helpers_package(mpeg2dec, , CFLAGS="$CFLAGS -D__CRT__NO_INLINE")

helpers_package(a52dec, , CFLAGS="$CFLAGS -D__CRT__NO_INLINE")

# helpers_package(openssl)

# helpers_package(curl)

helpers_package(fluidsynth-lite, -DCMAKE_TOOLCHAIN_FILE=$GCCSDK_INSTALL_ENV/toolchain-riscos.cmake)

helpers_package(freetype)

helpers_package(fribidi)

local_package(libsdl1.2)

helpers_package(sdl-net1.2)
