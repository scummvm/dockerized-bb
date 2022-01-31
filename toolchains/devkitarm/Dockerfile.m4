m4_define(`DEVKITARM_VERSION',20220128)
# This version of devkitARM depends on a Debian Buster
# For now it works with our version, we will have to ensure it stays like that
FROM devkitpro/devkitarm:DEVKITARM_VERSION AS original-toolchain

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		gnupg \
		libxml2 \
		make \
		pkg-config \
		xz-utils \
		&& \
	rm -rf /var/lib/apt/lists/*

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITARM=${DEVKITPRO}/devkitARM

# Copy ARM toolchain
COPY --from=original-toolchain ${DEVKITPRO}/ ${DEVKITPRO}

# All devkit libraries got installed

# Libraries will be built separately in NDS and 3DS toolchains
