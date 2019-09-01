FROM toolchains/common AS helpers

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

ENV PREFIX=/usr/x86_64-w64-mingw32 HOST=x86_64-w64-mingw32

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		gcc-mingw-w64-x86-64 \
		g++-mingw-w64-x86-64 \
		mingw-w64-tools \
		nasm \
		libz-mingw-w64-dev && \
	rm -rf /var/lib/apt/lists/* && \
	rm $PREFIX/lib/libz.dll.a
# Remove dynamic zlib as we never want to link dynamically with it

ENV \
	ACLOCAL_PATH=$PREFIX/share/aclocal \
	PKG_CONFIG_LIBDIR=$PREFIX/lib \
	PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
	CC=/usr/bin/$HOST-gcc \
	CPP=/usr/bin/$HOST-cpp \
	CXX=/usr/bin/$HOST-c++ \
	AR=/usr/bin/$HOST-ar \
	AS=/usr/bin/$HOST-as \
	CXXFILT=/usr/bin/$HOST-c++filt \
	GPROF=/usr/bin/$HOST-gprof \
	LD=/usr/bin/$HOST-ld \
	PKG_CONFIG=/usr/bin/$HOST-pkg-config \
	RANLIB=/usr/bin/$HOST-ranlib \
	STRIP=/usr/bin/$HOST-strip \
	STRINGS=/usr/bin/$HOST-strings \
	WIDL=/usr/bin/$HOST-widl \
	WINDMC=/usr/bin/$HOST-windmc \
	WINDRES=/usr/bin/$HOST-windres

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/
COPY functions-platform.sh lib-helpers/

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbis)

helpers_package(flac)

# For some currently unknown reason, inlining functions from stdlib.h fails and
# causes duplicate definitions with mingw-w64, so disable the inlining
helpers_package(mpeg2dec, , CFLAGS="$CFLAGS -D__CRT__NO_INLINE")

# For some currently unknown reason, inlining functions from stdlib.h fails and
# causes duplicate definitions with mingw-w64, so disable the inlining
helpers_package(a52dec, , CFLAGS="$CFLAGS -D__CRT__NO_INLINE")

helpers_package(curl, --without-ssl --with-winssl --with-winidn --disable-pthreads)

helpers_package(freetype)

local_package(libsdl2)

helpers_package(libsdl2-net)

helpers_package(fluidsynth-lite, -DCMAKE_SYSTEM_NAME=Windows)

local_package(winsparkle)
