m4_define(`TOOLCHAIN',macosx-arm64)m4_dnl
m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-18)m4_dnl
m4_define(`MACOSX_SDK_VERSION',15.5)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',aarch64)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',24.5)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',13.0)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`arm64')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`--arm64')m4_dnl
m4_dnl m4_define(`PATCH_OSXCROSS',`')m4_dnl
m4_include(`apple/macosx.m4')m4_dnl
