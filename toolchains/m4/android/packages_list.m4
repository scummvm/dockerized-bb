android_package(oboe)

m4_dnl This file is included by Dockerfile.m4
# zlib is already provided by Android but doesn't come with a pkg-config file
# This package just installs one to please libpng and others which require it
android_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, -DCMAKE_POSITION_INDEPENDENT_CODE=1)

helpers_package(giflib)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbis)

helpers_package(flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libmikmod)

helpers_package(libmpcdec)

# Setup Android build with everything needed
COPY --from=android-helpers /lib-helpers/packages/libvpx lib-helpers/packages/libvpx
helpers_package(libvpx, --enable-pic)

android_package(openssl)

helpers_package(curl)

helpers_package(freetype)

helpers_package(fribidi)

# Platform patch provided in android-common
# Don't depend on SDL2
COPY --from=android-helpers /lib-helpers/packages/libsdl2-net lib-helpers/packages/libsdl2-net
helpers_package(libsdl2-net)

helpers_package(fluidsynth)

helpers_package(sonivox)
