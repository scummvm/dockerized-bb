m4_dnl This file is included by Dockerfile.m4
# zlib is already provided by Android but doesn't come with a pkg-config file
# This package just installs one to please libpng and others which require it
local_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

# Copy platform patch
COPY packages/libvorbis lib-helpers/packages/libvorbis
helpers_package(libvorbis)

helpers_package(flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libiconv)

local_package(openssl)

helpers_package(curl)

helpers_package(freetype)

# Specific android patched version
local_package(libsdl2)

# Copy platform patch
# Don't depend on SDL2 (paradoxical)
# We have installed it but it depends on OpenGL so try to avoid these dependencies
COPY packages/libsdl2-net lib-helpers/packages/libsdl2-net
helpers_package(libsdl2-net)

# Copy platform patch
COPY packages/fluidsynth-lite lib-helpers/packages/fluidsynth-lite
helpers_package(fluidsynth-lite, -DBIN_INSTALL_DIR=bin/\$TARGET/\$API -DLIB_INSTALL_DIR=lib/\$TARGET/\$API)
