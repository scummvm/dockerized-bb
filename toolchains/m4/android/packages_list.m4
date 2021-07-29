m4_dnl This file is included by Dockerfile.m4
# zlib is already provided by Android but doesn't come with a pkg-config file
# This package just installs one to please libpng and others which require it
android_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, --with-pic)

helpers_package(giflib)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

# Platform patch provided in android-common
# Remove compilation flag not supported by clang
COPY --from=android-helpers /lib-helpers/packages/libvorbis lib-helpers/packages/libvorbis
helpers_package(libvorbis)

helpers_package(flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libiconv)

android_package(openssl)

helpers_package(curl)

helpers_package(freetype)

helpers_package(fribidi)

# Specific android patched version
android_package(libsdl2)

# Platform patch provided in android-common
# Don't depend on SDL2 (paradoxical)
# We have installed it but it depends on OpenGL so try to avoid these dependencies
COPY --from=android-helpers /lib-helpers/packages/libsdl2-net lib-helpers/packages/libsdl2-net
helpers_package(libsdl2-net)

helpers_package(fluidlite, -DBIN_INSTALL_DIR=bin/\$TARGET/\$API -DLIB_INSTALL_DIR=lib/\$TARGET/\$API)
