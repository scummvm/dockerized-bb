m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-18)m4_dnl
m4_define(`XOS_SDK_VERSION',18.5)m4_dnl
m4_define(`XOS_DEPLOYMENT_TARGET',9.0)m4_dnl

m4_define(`XOS_SDK_BASE',AppleTVOS)m4_dnl
m4_define(`XOS_PLATFORM',tv)m4_dnl

m4_include(`apple/xos.m4')m4_dnl

define_aliases(appletv, tvosbundle, --enable-static --with-staticlib-prefix=${PREFIX})
