m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-21)m4_dnl
m4_define(`MACOSX_SDK_VERSION',26.1)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',x86_64)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',25.1)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.9)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`x86_64')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`')m4_dnl
m4_dnl m4_define(`PATCH_OSXCROSS',`')m4_dnl
m4_include(`apple/macosx.m4')m4_dnl

# This package isn't available on older MacOS X
helpers_package(discord-rpc, -DCMAKE_SYSTEM_NAME=Darwin)

# This package isn't available for i386 so put it here
# It's in macosx-common for any MacOS toolchain
common_package(sparkle)

define_aliases(MACOSX_TARGET_ARCH`'-apple-darwin`'MACOSX_TARGET_VERSION, bundle, \
--enable-static --with-staticlib-prefix=${DESTDIR}/${PREFIX} --with-sparkle-prefix=${DESTDIR}/${PREFIX}/Library/Frameworks --disable-osx-dock-plugin, \
DISCORD_LIBS=\"-framework AppKit\")
