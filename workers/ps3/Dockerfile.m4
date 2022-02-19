FROM toolchains/ps3 AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV PS3DEV=/usr/local/ps3dev HOST=powerpc64-ps3-elf
ENV PSL1GHT=$PS3DEV PREFIX=$PS3DEV/portlibs/ppu

# Add libraries needed by toolchain to run
# Currently libgmp libssl zlib and python are already installed so don't add them
# That will be simpler when upgrading Debian and not having to adjust versions
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		python-is-python3 \
		libelf1 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $PS3DEV $PS3DEV/

# Copy Debian certificates for bundling by buildbot
RUN cp /etc/ssl/certs/ca-certificates.crt "$PS3DEV/cacert.pem"

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PS3DEV}/ppu/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PS3DEV}/ppu/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PS3DEV}/ppu/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PS3DEV}/bin:${PS3DEV}/ppu/bin:${PS3DEV}/spu/bin:${PS3DEV}/portlibs/ppu/bin

m4_include(`run-buildbot.m4')m4_dnl
