m4_define(`ALPINE_VERSION',3.20.2)m4_dnl
FROM alpine:ALPINE_VERSION
m4_define(`BASE_ALPINE',`')m4_dnl
USER root

m4_include(`install-buildbot.m4')m4_dnl

RUN mkdir -p /data/src /data/triggers && chown buildbot:buildbot /data/src /data/triggers
VOLUME /data/src /data/triggers

RUN apk add --no-cache git patch

m4_include(`run-buildbot.m4')m4_dnl
