m4_ifdef(`BASE_ALPINE',
RUN apk add --no-cache \
	dumb-init \
	py3-future \
	py3-pip \
	py3-twisted
, m4_ifdef(`BASE_DEBIAN',
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		dumb-init \
		python3-future \
		python3-pip \
		python3-twisted \
                && \
        rm -rf /var/lib/apt/lists/*
, ``fatal_error(No base defined)''))m4_dnl

ARG BUILDBOT_VERSION
LABEL buildbot-version=${BUILDBOT_VERSION}

RUN pip3 --no-cache-dir install --break-system-packages \
		buildbot-worker==${BUILDBOT_VERSION}

ARG BUILDBOT_UID=1000
ARG BUILDBOT_GID=1000
LABEL buildbot-uid=${BUILDBOT_UID} buildbot-gid=${BUILDBOT_GID}

m4_ifdef(`BASE_ALPINE',
RUN addgroup -g ${BUILDBOT_GID} buildbot && adduser -D -G buildbot -u ${BUILDBOT_UID} buildbot
, m4_ifdef(`BASE_DEBIAN',
RUN groupadd -g ${BUILDBOT_GID} buildbot && useradd -g ${BUILDBOT_GID} -u ${BUILDBOT_UID} buildbot
, ``fatal_error(No base defined)''))m4_dnl

RUN mkdir /buildbot-worker/ && chown buildbot:buildbot /buildbot-worker/

ADD "https://raw.githubusercontent.com/buildbot/buildbot/v${BUILDBOT_VERSION}/worker/docker/buildbot.tac" /buildbot-worker/
RUN chmod 644 /buildbot-worker/buildbot.tac
