FROM toolchains/raspberrypi AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV RPI_HOME=/opt/raspberrypi HOST=arm-linux-gnueabihf
ENV RPI_ROOT=$RPI_HOME/sysroot

COPY --from=toolchain $RPI_HOME $RPI_HOME/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${RPI_HOME}/bin/${HOST}-gcc \
	def_aclocal(`${RPI_ROOT}/usr') \
	PKG_CONFIG_LIBDIR=${RPI_ROOT}/usr/lib/$HOST/pkgconfig \
	PKG_CONFIG_SYSROOT_DIR=${RPI_ROOT} \
        PATH=$PATH:${RPI_HOME}/bin:${RPI_ROOT}/usr/bin

m4_include(`run-buildbot.m4')m4_dnl
