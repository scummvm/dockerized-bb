# This worker is used for old i386 only Mac
m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-11)m4_dnl
m4_define(`MACOSX_SDK_VERSION',10.13)m4_dnl
m4_define(`MACOSX_TARGET_ARCH',i386)m4_dnl
m4_define(`MACOSX_TARGET_VERSION',17)m4_dnl
m4_define(`MACOSX_DEPLOYMENT_TARGET',10.6)m4_dnl
m4_define(`MACOSX_ARCHITECTURES',`i386')m4_dnl
m4_define(`MACOSX_PORTS_ARCH_ARG',`--i386')m4_dnl
m4_include(`macosx.m4')m4_dnl

# Our compiler is c++11 compliant but our libstdc++ is too old for that
# So far it worked but several fixes are now needed
# glew needs cstdint
COPY cstdint ${TARGET_DIR}/SDK/MacOSX`'MACOSX_SDK_VERSION`'.sdk/usr/include/c++/4.2.1/cstdint
