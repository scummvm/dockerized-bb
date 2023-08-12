m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`DEBIAN_CLANG',-14)m4_dnl
m4_define(`MACOSX_SDK_VERSION',13.1)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',aarch64)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',22.2)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.16)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`arm64')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`--arm64')m4_dnl
m4_dnl m4_define(`PATCH_OSXCROSS',`')m4_dnl
m4_include(`apple/macosx.m4')m4_dnl

# This package isn't available on older MacOS X
helpers_package(discord-rpc, -DCMAKE_SYSTEM_NAME=Darwin)

# This package isn't available for i386 so put it here
# It's in macosx-common for any MacOS toolchain
common_package(sparkle)
