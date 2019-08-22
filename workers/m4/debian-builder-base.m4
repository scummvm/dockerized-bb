m4_define(`BASE_DEBIAN',`')m4_dnl
FROM debian:stable-slim
USER root

m4_include(`install-buildbot.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ccache \
		git \
		make \
		pkg-config \
		python \
		xz-utils \
		zip \
                && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/ccache /data/src /data/builds && chown buildbot:buildbot /data/ccache /data/src /data/builds
VOLUME /data/ccache /data/src /data/builds

ENV CCACHE_DIR=/data/ccache

