m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY functions-platform.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		flex \
		gcc \
		subversion && \
	rm -rf /var/lib/apt/lists/*

ENV HOST=arm-open2x-linux PREFIX=/opt/open2x

local_package(toolchain)

ENV \
	def_binaries(`${PREFIX}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PREFIX}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PREFIX}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin \
	CPPFLAGS="-I${PREFIX}/include -DDISABLE_X11 -DARM -D_ARM_ASSEM_" \
	CFLAGS="-O3 -ffast-math -fomit-frame-pointer -mcpu=arm920t" \
	CXXFLAGS="-O3 -ffast-math -fomit-frame-pointer -mcpu=arm920t" \
	LDFLAGS="-L${PREFIX}/lib"

helpers_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo)

helpers_package(giflib)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbisidec)

helpers_package(flac)

COPY packages/mpeg2dec lib-helpers/packages/mpeg2dec
helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(freetype)

helpers_package(fribidi)

local_package(libsdl)

# fluidsynth-lite is unlikely to be fast enough.
# The GP2X doesn't have network capabilities, so don't bother with sdl-net1.2 or curl
