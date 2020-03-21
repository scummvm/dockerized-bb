FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`pacman_package',`RUN dkp-pacman -Syy --noconfirm `$1' && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		gnupg \
		libxml2 \
		make \
		pkg-config \
		wget \
		xz-utils \
		&& \
	rm -rf /var/lib/apt/lists/*

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

ARG DKP_PACMAN=1.0.1

RUN wget https://github.com/devkitPro/pacman/releases/download/devkitpro-pacman-${DKP_PACMAN}/devkitpro-pacman.deb && \
	dpkg -i devkitpro-pacman.deb && \
	rm -f $HOME/.wget-hsts devkitpro-pacman.deb && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*

pacman_package(nds-dev 3ds-dev)

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITARM=${DEVKITPRO}/devkitARM

# Libraries will be built or installed separately in NDS and 3DS toolchains
