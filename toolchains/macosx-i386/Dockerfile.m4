# This toolchain is used for old x86 only Mac
m4_define(`PPA_CLANG',-10)m4_dnl
m4_define(`MACOSX_SDK_VERSION',10.13)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',i386)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',17)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.6)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`i386')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`--i386')m4_dnl
m4_include(`macosx.m4')m4_dnl
