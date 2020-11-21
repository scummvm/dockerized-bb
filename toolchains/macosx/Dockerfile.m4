m4_define(`PPA_CLANG',-10)m4_dnl
m4_define(`MACOSX_SDK_VERSION',10.15)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',x86_64)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',19)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.9)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`x86_64')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`')m4_dnl
m4_include(`macosx.m4')m4_dnl

# This package isn't available on older MacOS X
helpers_package(discord-rpc, -DCMAKE_SYSTEM_NAME=Darwin)

# This package isn't available for i386 so put it here
# It's in macosx-common for any ARM toolchain
common_package(sparkle)
