FROM toolchains/psp AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

COPY --from=toolchain $PSPDEV $PSPDEV/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PSPDEV}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PSPDEV}/bin:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
