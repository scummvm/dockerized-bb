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

# Use a common build script for vdpm packages
COPY packages/common lib-helpers/packages/common/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libc6-i386 \
		lib32stdc++6 \
		lib32gcc1 && \
	rm -rf /var/lib/apt/lists/*

ENV VITASDK=/usr/local/vitasdk HOST=arm-vita-eabi
ENV PREFIX=$VITASDK/$HOST

local_package(toolchain)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${VITASDK}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${VITASDK}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${VITASDK}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${VITASDK}/bin:${PREFIX}/bin

local_package(zlib)

local_package(libpng)

local_package(libjpeg-turbo)

local_package(libmad)

local_package(libogg)

local_package(libvorbis)

helpers_package(libtheora)

local_package(flac)

helpers_package(faad2)

local_package(libmpeg2)

# These functions aren't implemented on Vita but they are not needed either
helpers_package(libiconv, , ac_cv_func_sigprocmask=yes ac_cv_func_getprogname=yes)

local_package(openssl)

local_package(curl)

local_package(freetype)

helpers_package(fribidi)

local_package(sdl2)

local_package(sdl2_net)

local_package(vita2dlib_fbo)

local_package(vita-shader-collection)
