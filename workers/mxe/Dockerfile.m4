FROM toolchains/mxe AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

# nasm is used for x86 ScummVM
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		nasm \
		dos2unix && \
	rm -rf /var/lib/apt/lists/*

ENV MXE_PREFIX_DIR=/opt/mxe

COPY --from=toolchain ${MXE_PREFIX_DIR} ${MXE_PREFIX_DIR}/

# Add MXE bin directory to PATH
ENV PATH=$PATH:${MXE_PREFIX_DIR}/bin

m4_include(`run-buildbot.m4')m4_dnl
