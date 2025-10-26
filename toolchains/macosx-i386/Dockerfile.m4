# This worker is used for old i386 only Mac
m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`DEBIAN_CLANG',-19)m4_dnl
m4_define(`MACOSX_SDK_VERSION',10.13)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',i386)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',17)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.6)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`i386')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`--i386')m4_dnl

m4_dnl Fluidsynth uses C++11 stdlib features which are not provided on this old platform
m4_define(`USE_FLUIDLITE')m4_dnl

m4_include(`apple/macosx.m4')m4_dnl

local_package(sdk10.13-patcher)

define_aliases(MACOSX_TARGET_ARCH`'-apple-darwin`'MACOSX_TARGET_VERSION, bundle, --enable-static --with-staticlib-prefix=${DESTDIR}/${PREFIX} --disable-osx-dock-plugin)
