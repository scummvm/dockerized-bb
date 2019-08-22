FROM toolchains/common AS helpers

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

ENV VITASDK=/usr/local/vitasdk HOST=arm-vita-eabi
ENV PREFIX=$VITASDK/$HOST

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libc6-i386 \
		lib32stdc++6 \
		lib32gcc1 && \
	rm -rf /var/lib/apt/lists/*

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/
COPY functions-platform.sh lib-helpers/

local_package(toolchain)

ENV \
	ACLOCAL_PATH=$PREFIX/share/aclocal \
	PKG_CONFIG_LIBDIR=$PREFIX/lib \
	PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
	CC=$VITASDK/bin/$HOST-gcc \
	CPP=$VITASDK/bin/$HOST-cpp \
	CXX=$VITASDK/bin/$HOST-c++ \
	AR=$VITASDK/bin/$HOST-ar \
	AS=$VITASDK/bin/$HOST-as \
	CXXFILT=$VITASDK/bin/$HOST-c++filt \
	GPROF=$VITASDK/bin/$HOST-gprof \
	LD=$VITASDK/bin/$HOST-ld \
	RANLIB=$VITASDK/bin/$HOST-ranlib \
	STRIP=$VITASDK/bin/$HOST-strip \
	STRINGS=$VITASDK/bin/$HOST-strings

local_package(zlib)

local_package(libpng)

local_package(libjpeg-turbo)

local_package(libmad)

local_package(libogg)

local_package(libvorbis)

helpers_package(libtheora)

local_package(flac)

helpers_package(faad2)

helpers_package(mpeg2dec, , CFLAGS="$CFLAGS -D__CRT__NO_INLINE")

local_package(openssl)

local_package(curl)

local_package(freetype)

local_package(sdl2)

local_package(sdl2_net)

local_package(vita2dlib_fbo)

local_package(vita-shader-collection)
