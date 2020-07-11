FROM toolchains/common AS helpers

# This version of devkitARM depends on a Debian Stretch
# For now it works with stable-slim, we will have to ensure it stays like that
FROM devkitpro/devkitarm:20200528 AS original-toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		curl \
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
