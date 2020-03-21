FROM toolchains/devkitswitch AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITA64=${DEVKITPRO}/devkitA64
ENV PREFIX=${DEVKITPRO}/portlibs/switch HOST=aarch64-none-elf

COPY --from=toolchain ${DEVKITPRO}/devkitA64 ${DEVKITPRO}/devkitA64/
COPY --from=toolchain ${DEVKITPRO}/libnx ${DEVKITPRO}/libnx/
COPY --from=toolchain ${DEVKITPRO}/portlibs/switch ${DEVKITPRO}/portlibs/switch/
COPY --from=toolchain ${DEVKITPRO}/tools ${DEVKITPRO}/tools/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITA64}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/switch/bin

m4_include(`run-buildbot.m4')m4_dnl
