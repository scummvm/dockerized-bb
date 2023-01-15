import datetime
import os

from twisted.cred import strcred

from buildbot.plugins import util
from buildbot.plugins import reporters

# To patch janitor name
import buildbot.configurators.janitor

import config

www = {
    'plugins': {
        'waterfall_view': True,
        'console_view': True,
        'grid_view': True,
    },
    'avatar_methods': [],
    # Prepare change hooks if any
    'change_hook_dialects': {
    },
}
services = []

if hasattr(config, 'github_avatars') and config.github_avatars:
    token = (hasattr(config, 'github_token') and config.github_token) or None
    www['avatar_methods'].append(util.AvatarGitHub(token=token))

if hasattr(config, 'github_webhook_secret'):
    www['change_hook_dialects']['github'] = {
	'secret': config.github_webhook_secret,
        # Only be strict when secret is provided
        # When not strict, if no signature is returned, check isn't done
        'strict': bool(config.github_webhook_secret),
    }

if hasattr(config, 'ht_auth_file') and config.ht_auth_file:
    ht_auth_file = os.path.join(config.configuration_dir, config.ht_auth_file)
    www['auth'] = util.HTPasswdAuth(ht_auth_file)
    # When using htpasswd file, we don't have any group information nor email information
    www['authz'] = util.Authz(
        stringsMatcher=util.fnmatchStrMatcher,  # simple matcher with '*' glob character
        allowRules=[
            # admins can do anything,
            # defaultDeny=False: if user does not have the admin role, we continue parsing rules
            util.AnyEndpointMatcher(role="admin", defaultDeny=False),
            # if future Buildbot implement new control, we are safe with this last rule
            util.AnyControlEndpointMatcher(role="admin")
        ],
        roleMatchers=[
            util.RolesFromUsername(roles=['admin'], usernames=config.ht_auth_admins),
        ]
    )
elif hasattr(config, 'github_auth_clientid') and config.github_auth_clientid:
    www['auth'] = util.GitHubAuth(
            config.github_auth_clientid, config.github_auth_clientsecret,
            apiVersion=4, getTeamsMembership=True)
    # When using Github authentication, we can use group membership information
    www['authz'] = util.Authz(
        stringsMatcher=util.fnmatchStrMatcher,  # simple matcher with '*' glob character
        # stringsMatcher = util.reStrMatcher,   # if you prefer regular expressions
        allowRules=[
            # admins can do anything,
            # defaultDeny=False: if user does not have the admin role, we continue parsing rules
            util.AnyEndpointMatcher(role=config.github_admin_group, defaultDeny=False),
            # Let owner stop its build
            util.StopBuildEndpointMatcher(role="owner"),
            # if future Buildbot implement new control, we are safe with this last rule
            util.AnyControlEndpointMatcher(role=config.github_admin_group)
        ],
        roleMatchers=[
            util.RolesFromGroups(groupPrefix="{0}/".format(config.github_organization)),
            # role owner is granted when property owner matches the email of the user
            util.RolesFromOwner(role="owner")
        ]
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
        useSASL=config.irc.get('sasl', False),
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
        ]
    ))

if hasattr(config, 'discord_reporter') and config.discord_reporter:
    from utils import discord
    from buildbot.reporters.generators.buildset import BuildSetStatusGenerator
    from buildbot.reporters.generators.build import BuildStatusGenerator
    if hasattr(config, 'discord_mentions'):
        discord_mentions = config.discord_mentions
    else:
        discord_mentions = None
    services.append(discord.DiscordStatusPush(config.discord_reporter,
        mentions=discord_mentions,
        generators=[
            BuildSetStatusGenerator(
                message_formatter=discord.DiscordFormatter(),
                # Only report builder aggregated in a buildset and not fetch or daily
                tags=['build'],
                mode=("change", "exception")),
            BuildStatusGenerator(
                message_formatter=discord.DiscordFormatter(),
                # Report cleanup too
                tags=['cleanup'],
                mode=("change", "exception"))
    ]))

if hasattr(config, 'enable_list_daily_builds') and config.enable_list_daily_builds:
    serve_daily_builds = hasattr(config, 'serve_daily_builds') and config.serve_daily_builds
    import builds, platforms
    from utils import list_daily_builds
    from utils import scummsteps
    www['plugins']['wsgi_dashboards'] = [{
        'name': 'dailybuilds',
        'caption': 'Daily builds',
        'app': list_daily_builds.get_application(
            (scummsteps.create_names, scummsteps.parse_package_name),
            config.daily_builds_dir, config.daily_builds_url,
            builds.builds, platforms.platforms,
            serve_daily_builds = serve_daily_builds),
        'order': -1,
        'icon': 'archive'
    }]

buildbot.configurators.janitor.JANITOR_NAME = "zzz_janitor"
janitor = util.JanitorConfigurator(
    logHorizon=datetime.timedelta(
        weeks=config.data_retention_weeks)
        if hasattr(config, 'data_retention_weeks') else None,
    build_data_horizon=datetime.timedelta(
        weeks=config.data_retention_weeks)
        if hasattr(config, 'data_retention_weeks') else None,
    # 5 o'clock on sundays
    hour=5,
    dayOfWeek=6
)
