FROM toolchains/caanoo AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV CAANOO=/opt/caanoo HOST=arm-gph-linux-gnueabi

COPY --from=toolchain $CAANOO $CAANOO/

ENV PREFIX=${CAANOO}/${HOST}/sysroot/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${CAANOO}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${CAANOO}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${CAANOO}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
