FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM i386/debian:stable-slim
USER root

WORKDIR /usr/src

ENV PREFIX=/opt/open2x/gcc-4.1.1-glibc-2.3.6 HOST=arm-open2x-linux

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

local_package(toolchain)

ENV \
	def_binaries(`${PREFIX}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PREFIX}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PREFIX}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=${PREFIX}/bin:$PATH \
	CPPFLAGS="-I${PREFIX}/include -DDISABLE_X11" \
	LDFLAGS="-L${PREFIX}/lib"

local_package(shared-libs)

# We already have the following shared libraries:
#  - libfreetype.so.6.3.8
#  - libjpeg.so.62.0.0
#  - libmad.so.0.2.1
#  - libogg.so.0.5.3
#  - libpng.so.3.15.0
#  - libpng12.so.0.15.0
#  - libreadline.so.5.1
#  - libSDL-1.2.so.0.7.2
#  - libvorbis.so.0.3.1
#  - libvorbisenc.so.2.0.2
#  - libvorbisfile.so.3.1.1
#  - libvorbisidec.so.1.0.2
#  - libz.so.1.2.3

helpers_package(faad2)

local_package(mpeg2dec)

helpers_package(a52dec)

# libtheora, flac and fluidsynth-lite are unlikely to be fast enough.
# The GP2X and Wiz don't have network capabilities, so don't bother with sdl-net1.2 or curl
