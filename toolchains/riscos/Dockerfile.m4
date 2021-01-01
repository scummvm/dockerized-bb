FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl

m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl

m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/
COPY functions-platform.sh lib-helpers/

COPY multi-build.sh lib-helpers/

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

ENV PREFIX=${GCCSDK_INSTALL_ENV} HOST=arm-unknown-riscos

# Put GCCSDK_INSTALL_CROSSBIN before PATH because it overrides some binaries like zip
ENV \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `gcc, cpp, c++') \
	CC=$GCCSDK_INSTALL_CROSSBIN/$HOST-gcc \
	PATH=$GCCSDK_INSTALL_CROSSBIN:$PATH \
	CFLAGS="-ffunction-sections -fdata-sections -mno-poke-function-name" \
	CXXFLAGS="-ffunction-sections -fdata-sections -mno-poke-function-name" \
	LDFLAGS="-Wl,--gc-sections" \
	CFLAGS_STD="-O2" \
	CXXFLAGS_STD="-O2" \
	ASFLAGS_VFP="-mfpu=vfp" \
	CFLAGS_VFP="-mfpu=vfp" \
	CXXFLAGS_VFP="-mfpu=vfp" \
	LDFLAGS_VFP="-mfpu=vfp"

helpers_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libvorbisidec)

helpers_package(libtheora)

helpers_package(flac, --with-pic=no)

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

# helpers_package(openssl)

# helpers_package(curl)

helpers_package(fluidsynth-lite, -DCMAKE_TOOLCHAIN_FILE=$GCCSDK_INSTALL_ENV/toolchain-riscos.cmake)

helpers_package(freetype)

helpers_package(fribidi)

local_package(libsdl1.2)

helpers_package(sdl-net1.2)
