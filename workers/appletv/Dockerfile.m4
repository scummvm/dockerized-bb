FROM toolchains/appletv AS toolchain

m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`DEBIAN_CLANG',-14)m4_dnl
m4_define(`XOS_SDK_VERSION',16.1)m4_dnl
m4_define(`XOS_DEPLOYMENT_TARGET',9.0)m4_dnl

m4_define(`XOS_SDK_BASE',AppleTVOS)m4_dnl
m4_define(`XOS_PLATFORM',tv)m4_dnl

m4_include(`apple/xos.m4')m4_dnl
