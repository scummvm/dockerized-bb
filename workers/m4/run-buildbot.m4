USER buildbot
WORKDIR /buildbot-worker/

ENTRYPOINT ["/usr/bin/dumb-init", m4_ifdef(`ENTRY_WRAPPER',ENTRY_WRAPPER`, ')"/opt/buildbot/bin/twistd", "--pidfile=", "-ny", "buildbot.tac"]
