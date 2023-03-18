FROM toolchains/psp AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

# Add libraries needed by toolchain to run
# Currently libgmp is already installed so don't add it
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libmpc3 \
		libmpfr6 \
		libisl23 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $PSPDEV $PSPDEV/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PSPDEV}/bin/${HOST}-gcc \
	CFLAGS="-I${PSPDEV}/psp/include -I${PSPDEV}/psp/sdk/include -DPSP -O2 -G0" \
	CXXFLAGS="-I${PSPDEV}/psp/include -I${PSPDEV}/psp/sdk/include -DPSP -O2 -G0" \
	LDFLAGS="-L${PSPDEV}/lib -L${PSPDEV}/psp/lib -L${PSPDEV}/psp/sdk/lib -Wl,-zmax-page-size=128" \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PSPDEV}/bin:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
