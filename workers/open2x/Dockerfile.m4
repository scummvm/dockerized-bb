FROM toolchains/open2x AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV HOST=arm-open2x-linux PREFIX=/opt/open2x

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $PREFIX $PREFIX/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PREFIX}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PREFIX}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PREFIX}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin \
	CPPFLAGS="-isystem ${PREFIX}/include -DDISABLE_X11 -DARM -D_ARM_ASSEM_" \
	CFLAGS="-O3 -ffast-math -fomit-frame-pointer -mcpu=arm920t" \
	CXXFLAGS="-O3 -ffast-math -fomit-frame-pointer -mcpu=arm920t" \
	LDFLAGS="-L${PREFIX}/lib"

m4_include(`run-buildbot.m4')m4_dnl
