FROM toolchains/ps2 AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV PS2DEV=/usr/local/ps2dev HOST=ps2
ENV PS2SDK=$PS2DEV/ps2sdk
ENV PREFIX=$PS2SDK/ports

# Add libraries needed by toolchain to run
#RUN apt-get update && \
#	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#		libelf1 && \
#	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $PS2DEV $PS2DEV/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PS2DEV}/ee/bin/ee-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PS2DEV}/ee/bin/ee-', `gcc, cpp, c++') \
	CC=${PS2DEV}/ee/bin/ee-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PS2DEV}/bin:${PS2DEV}/ee/bin:${PS2DEV}/dvp/bin:${PS2DEV}/iop/bin:${PS2SDK}/bin:${PS2SDK}/ports/bin

ENV \
	CPPFLAGS="-isystem${PS2SDK}/ee/include -isystem${PS2SDK}/common/include -isystem${PREFIX}/include -isystem${PS2DEV}/isjpcm/include" \
	LDFLAGS="-L${PS2SDK}/ee/lib -L${PREFIX}/lib -L${PS2DEV}/isjpcm/lib"

m4_include(`run-buildbot.m4')m4_dnl
