USER buildbot
WORKDIR /buildbot-worker/

m4_ifdef(`BASE_ALPINE',
``ENTRYPOINT ["/usr/bin/dumb-init", ''m4_ifdef(`ENTRY_WRAPPER',`ENTRY_WRAPPER``, ''')``"twistd", "--pidfile=", "-ny", "buildbot.tac"]''
, m4_ifdef(`BASE_DEBIAN',
``ENTRYPOINT ["/usr/bin/dumb-init", ''m4_ifdef(`ENTRY_WRAPPER',`ENTRY_WRAPPER``, ''')``"twistd3", "--pidfile=", "-ny", "buildbot.tac"]''
, ``fatal_error(No base defined)''))m4_dnl
