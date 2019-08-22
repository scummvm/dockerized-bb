import os

from buildbot.www.authz import Authz
from buildbot.www.auth import HTPasswdAuth
from twisted.cred import strcred

import config

htfile = os.path.join(config.buildbot_base_dir, config.htfile)
changehook_passwd = os.path.join(config.buildbot_base_dir, config.changehook_passwd)
web_authz = None

www = {
    'plugins': dict(waterfall_view={}, console_view={}, grid_view={}),
# TODO:
#    order_console_by_time: True,
}

if os.path.exists(htfile):
    www['authz'] = Authz(auth=HTPasswdAuth(htfile),
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

if os.path.exists(changehook_passwd):
    www['change_hook_auth'] = [strcred.makeChecker("file:{0}".format(changehook_passwd))]
    www['change_hook_dialects'] = {'github': True}

services = []
