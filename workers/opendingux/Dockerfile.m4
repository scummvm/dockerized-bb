FROM toolchains/opendingux AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV DINGUX_TOOLCHAIN=/opt/dingux-toolchain HOST=mipsel-unknown-linux-uclibc

COPY --from=toolchain ${DINGUX_TOOLCHAIN} ${DINGUX_TOOLCHAIN}/

ENV PREFIX=${DINGUX_TOOLCHAIN}/${HOST}/sysroot/usr

# We add PATH here for *-config and platform specific binaries
# *FLAGS are already set in configure script
ENV \
	def_binaries(`${DINGUX_TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DINGUX_TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DINGUX_TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
