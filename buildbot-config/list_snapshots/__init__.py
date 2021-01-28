import collections
import os
import sys
import urllib.parse as urlp

from zope.interface import implementer
from buildbot.interfaces import IConfigured

import bottle
from bottle import jinja2_template as template, jinja2_view as view
from bottle import request, response

#bottle.debug()

__all__ = [ 'get_application' ]

# PackageInfo is generic and is built at startup
PackageInfo = collections.namedtuple('PackageInfo', ['path', 'base_url'])
# SnapshotInfo is resolved in real time from a PackageInfo
SnapshotInfo = collections.namedtuple('SnaphshotInfo', ['revision', 'url'])
Helpers = collections.namedtuple('Helpers', ['get_names', 'get_revision'])

# Subclass Bottle to have a pretty configuration
@implementer(IConfigured)
class ConfiguredBottle(bottle.Bottle):
    def getConfigDict(self):
        # Return module name
        return dict(name=__name__)

module_path = os.path.abspath(os.path.dirname(__file__))
static_path = os.path.join(module_path, 'static')
tmpl_path = [os.path.join(module_path, 'templates')]

def get_application(
        helpers,
        snapshots_dir, snapshots_url,
        builds, platforms, serve_snapshots=False):

    helpers = Helpers(*helpers)

    packaged_builds, packaged_platforms = get_packaged_data(
        snapshots_dir, snapshots_url, helpers,
        builds, platforms)

    app = ConfiguredBottle(catchall=False, autojson=False)

    app.helpers = helpers
    app.packaged_builds = packaged_builds
    app.packaged_platforms = packaged_platforms

    # Register routes
    app.route('/', callback=list_snapshots)
    app.route('/index.html', callback=list_snapshots)
    app.route('/static/<filepath:re:.*>', callback=static)
    if serve_snapshots:
        app.snapshots_dir = snapshots_dir
        app.route('/packages/<filepath:re:.*>', callback=packages)

    return app

def get_packaged_data(snapshots_dir, snapshots_url, helpers,
        builds, platforms):
    packaged_builds = set()
    packaged_platforms = collections.OrderedDict()

    platforms = sorted(platforms, key=lambda x: x.description.lower())

    for platform in platforms:
        packaged_platform_builds = dict()
        for build in builds:
            if platform.canBuild(build) and platform.canPackage(build):
                packaged_platform_builds[build] = get_package_infos(
                    snapshots_dir, snapshots_url, helpers,
                    build, platform)

        if packaged_platform_builds:
            packaged_builds |= packaged_platform_builds.keys()
            packaged_platforms[platform] = packaged_platform_builds

    packaged_builds = sorted(packaged_builds, key=lambda x: x.description.lower())

    return packaged_builds, packaged_platforms

def get_package_infos(snapshots_dir, snapshots_url, helpers,
        build, platform):

    _, _, symlink = helpers[0](
            buildname=build.name,
            platformname=platform.name,
            archive_format=platform.archiveext,
            revision=None)
    path = os.path.join(snapshots_dir, build.name, symlink)

    base_url = urlp.urljoin(snapshots_url + '/', build.name + '/')

    return PackageInfo(path, base_url)

# Filter for list_snapshots template
# Determine the revision pointed by symlink
def to_snapshot(pkg_info):
    helpers = request.app.helpers

    path = os.path.realpath(pkg_info.path)
    if not os.path.isfile(path):
        # Either a broken symlink, a directory(?), ...
        return False

    basename = os.path.basename(path)
    # Create a revision dependent URL
    url = urlp.urljoin(pkg_info.base_url, basename)

    rev = helpers[1](basename)

    return SnapshotInfo(rev, url)

# Build an URL pointing to assets
def static_url(item):
    # Remove leading / as we are relative to main page
    base_url = request.script_name.lstrip('/') + '/'
    url = urlp.urljoin(base_url, 'static/{0}'.format(item))
    return url

# Route for index.html
@view('list_snapshots.tmpl',
    template_lookup=tmpl_path,
    template_settings=dict(
        filters={
            'to_snapshot': to_snapshot,
            'static_url': static_url,
        },
    ))
def list_snapshots():
    ret = dict()
    ret['builds'] = request.app.packaged_builds
    ret['platforms'] = request.app.packaged_platforms
    return ret

# Static Routes
# for assets (CSS) in /static/
def static(filepath):
    return bottle.static_file(filepath, root=static_path)
# for snapshots in /packages/
def packages(filepath):
    return bottle.static_file(filepath, root=request.app.snapshots_dir)
