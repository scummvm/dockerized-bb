m4_define(`GCW0_VERSION', 2021-03-10)
m4_define(`LEPUS_VERSION', 2021-03-11)
m4_define(`RS90_VERSION', 2021-03-10)

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

ENV OPENDINGUX_ROOT=/opt/opendingux

local_sdk_package(toolchain,gcw0 GCW0_VERSION)
local_sdk_package(toolchain,lepus LEPUS_VERSION)
local_sdk_package(toolchain,rs90 RS90_VERSION)

COPY multi-build.sh lib-helpers/

# zlib is already installed in original toolchain

# libpng is already installed in original toolchain

# libjpeg is already installed in original toolchain

helpers_package(giflib)

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libvorbis is already installed in original toolchain

# libvorbisidec is already installed in original toolchain

# libtheora is already installed in original toolchain

# flac is already installed in original toolchain

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

# No curl support in configure

# freetype is already installed in original toolchain

helpers_package(fribidi)

# sdl2 is already installed in original toolchain

# sdl2_net is already installed in original toolchain

# fluidsynth is already installed in original toolchain
