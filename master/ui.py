import os

from twisted.cred import strcred

from buildbot.plugins import util
from buildbot.plugins import reporters

import config

htfile = os.path.join(config.buildbot_base_dir, config.htfile)
web_authz = None

www = {
    'plugins': dict(waterfall_view={}, console_view={}, grid_view={}),
# TODO:
#    order_console_by_time: True,
    'change_hook_dialects': {
    },
}
services = []

if hasattr(config, 'github_webhook_secret'):
    www['change_hook_dialects']['github'] = {
	'secret': config.github_webhook_secret,
        # Only be strict when secret is provided
        # When not strict, if no signature is returned, check isn't done
        'strict': bool(config.github_webhook_secret),
    }

if os.path.exists(htfile):
    www['authz'] = util.Authz(auth=util.HTPasswdAuth(htfile),
            forceBuild='auth', # only authenticated users
            forceAllBuilds='auth', # only authenticated users
            stopBuild='auth', # only authenticated users
            stopAllBuilds='auth', # only authenticated users
            cancelPendingBuild='auth', # only authenticated users
    )

try:
    if len(config.www_port) == 2:
        www['port'] = "tcp:{1}:interface={0}".format(*config.www_port)
    elif len(config.www_port) == 1:
        www['port'] = "tcp:{0}".format(*config.www_port)
    else:
        raise Exception("www_port hasn't length 2")
except TypeError:
    www['port'] = "tcp:{0}".format(config.www_port)

if hasattr(config, 'irc') and config.irc:
    services.append(reporters.IRC(
        host=config.irc['server'],
        port=config.irc.get('port', 6667),
        useSSL=config.irc.get('ssl', False),
        nick=config.irc['nick'],
        password=config.irc.get('password', None),
        channels=config.irc.get('channels', []),
        pm_to_nicks=config.irc.get('nicks', []),
        useColors=True,
        authz={
            # Order of match is 'command', '*', ''/'!'
            # Operation restricted to bot administrators
            '': config.irc.get('admins', False),
            # No dangerous command can be issued on IRC (real authentication required)
            '!': False,
        },
        notify_events=[
            'exception',
            'problem',
            'recovery',
            'worker'
        ]
    ))
