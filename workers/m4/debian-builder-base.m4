m4_define(`BASE_DEBIAN',`')m4_dnl
FROM debian:stable-slim
USER root

m4_include(`install-buildbot.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ccache \
		git \
		make \
		pandoc \
		pkg-config \
		python \
		xz-utils \
		zip \
                && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/ccache /data/src /data/builds /data/bshomes && \
	chown buildbot:buildbot /data/ccache /data/src /data/builds /data/bshomes
VOLUME /data/ccache /data/src /data/builds /data/bshomes

ENV CCACHE_DIR=/data/ccache

