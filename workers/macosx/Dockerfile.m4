m4_define(`TOOLCHAIN',macosx)m4_dnl
m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-10)m4_dnl
m4_define(`MACOSX_SDK_VERSION',11.1)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',x86_64)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',21)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.9)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`x86_64')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`')m4_dnl
m4_dnl We provide specific patch to add 11.1 support
m4_define(`PATCH_OSXCROSS',`')m4_dnl
m4_include(`macosx.m4')m4_dnl
