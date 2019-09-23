FROM toolchains/devkitppc AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITPPC=${DEVKITPRO}/devkitPPC
ENV PREFIX=${DEVKITPRO}/portlibs/ppc HOST=powerpc-eabi

COPY --from=toolchain ${DEVKITPRO}/devkitPPC ${DEVKITPRO}/devkitPPC/
COPY --from=toolchain ${DEVKITPRO}/portlibs ${DEVKITPRO}/portlibs/
COPY --from=toolchain ${DEVKITPRO}/libogc ${DEVKITPRO}/libogc/
COPY --from=toolchain ${DEVKITPRO}/tools ${DEVKITPRO}/tools/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITPPC}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/bin

m4_include(`run-buildbot.m4')m4_dnl
