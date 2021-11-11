FROM toolchains/opendingux-beta AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		squashfs-tools && \
	rm -rf /var/lib/apt/lists/*

ENV OPENDINGUX_ROOT=/opt/opendingux

COPY --from=toolchain ${OPENDINGUX_ROOT} ${OPENDINGUX_ROOT}/

# These flags are set by buildroot in all OpenDingux toolchains
ENV \
	CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64"
m4_include(`run-buildbot.m4')m4_dnl
