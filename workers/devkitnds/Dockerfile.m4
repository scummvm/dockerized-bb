FROM toolchains/devkitnds AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITARM=${DEVKITPRO}/devkitARM
ENV PREFIX=${DEVKITPRO}/portlibs/nds HOST=arm-none-eabi

COPY --from=toolchain ${DEVKITPRO}/devkitARM ${DEVKITPRO}/devkitARM/
COPY --from=toolchain ${DEVKITPRO}/libnds ${DEVKITPRO}/libnds/
COPY --from=toolchain ${DEVKITPRO}/portlibs/nds ${DEVKITPRO}/portlibs/nds/
COPY --from=toolchain ${DEVKITPRO}/tools ${DEVKITPRO}/tools/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITARM}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/nds/bin

m4_include(`run-buildbot.m4')m4_dnl
