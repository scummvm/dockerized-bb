m4_ifdef(`DEBIAN_RELEASE',,`m4_define(`DEBIAN_RELEASE',bullseye)')
m4_ifdef(`DEBIAN_VERSION',,`m4_define(`DEBIAN_VERSION',20230502)')
m4_define(`BASE_DEBIAN',`')m4_dnl
FROM debian:DEBIAN_RELEASE-DEBIAN_VERSION-slim
USER root

m4_include(`install-buildbot.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ccache \
		curl \
		git \
		make \
		pandoc \
		pkg-config \
		python3 \
		python-is-python3 \
		xz-utils \
		zip \
                && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/bshomes /data/build /data/ccache /data/src && \
	chown buildbot:buildbot /data/bshomes /data/build /data/ccache /data/src
VOLUME /data/bshomes /data/build /data/ccache /data/src

ENV CCACHE_DIR=/data/ccache

