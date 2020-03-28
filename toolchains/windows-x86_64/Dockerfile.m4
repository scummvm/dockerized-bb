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
		gcc-mingw-w64-x86-64 \
		g++-mingw-w64-x86-64 \
		mingw-w64-tools \
		nasm \
		libz-mingw-w64-dev && \
	rm -rf /var/lib/apt/lists/* && \
	rm /usr/x86_64-w64-mingw32/lib/libz.dll.a
# Remove dynamic zlib as we never want to link dynamically with it

ENV PREFIX=/usr/x86_64-w64-mingw32 HOST=x86_64-w64-mingw32

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`/usr/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/${HOST}-', `widl, windmc, windres') \
	def_binaries(`/usr/bin/${HOST}-', `gcc, cpp, c++') \
	def_binaries(`/usr/bin/${HOST}-', `pkg-config') \
	CC=/usr/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PREFIX}/bin

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
