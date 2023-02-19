FROM toolchains/miyoo AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV MIYOO_ROOT=/opt/miyoo HOST=arm-miyoo-linux-uclibcgnueabi

COPY --from=toolchain ${MIYOO_ROOT} ${MIYOO_ROOT}/

ENV PREFIX=${MIYOO_ROOT}/${HOST}/sysroot/usr

# We add PATH here for *-config and platform specific binaries
# *FLAGS are already set in configure script
ENV \
	def_binaries(`${MIYOO_ROOT}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${MIYOO_ROOT}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${MIYOO_ROOT}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PKG_CONFIG_SYSROOT_DIR=${MIYOO_ROOT}/${HOST}/sysroot \
	PATH=$PATH:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
