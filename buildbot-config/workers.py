import collections
import os
import random
import string
import subprocess

import docker

from buildbot.plugins import util
from buildbot.plugins import worker

import config

workers = []
# This will contain lists of worker names by type for builds module
workers_by_type = collections.defaultdict(list)

def register(type_, worker):
    workers.append(worker)
    workers_by_type[type_].append(worker.name)

docker_client = docker.APIClient(base_url=config.docker_socket)
if len(docker_client.networks(names=[config.docker_workers_net])) == 0:
	docker_client.create_network(config.docker_workers_net)

buildbot_ip = docker_client.inspect_network(config.docker_workers_net)['IPAM']['Config'][0]['Gateway']

# Those are setup in docker images
BUILDBOT_UID, BUILDBOT_GID = 1000, 1000

## Helper to determine uid:gid used by docker
def get_base_uid_gid(client):
    info = client.info()
    if ('SecurityOptions' not in info or
            'name=userns' not in info['SecurityOptions']):
        return 0, 0

    root_dir = info.get('DockerRootDir', '')
    basename = os.path.basename(root_dir)

    if '.' not in basename:
        return 0, 0

    uid, gid = basename.split('.', maxsplit=1)
    uid = int(uid, 10)
    gid = int(gid, 10)

    return uid, gid
buildbot_root_uid, buildbot_root_gid = get_base_uid_gid(docker_client)

# Helper to setup correct ACLs
def apply_acls(volume, uid, gid):
    subprocess.run(["setfacl", "-m", "user:{0}:rwx".format(uid), volume], check=True)
    subprocess.run(["setfacl", "-m", "group:{0}:rwx".format(gid), volume], check=True)

# The worker used for all build stuff, image name depends on build property
def StandardBuilderWorker(name, **kwargs):
    volumes = {
        '{0}/bshomes'.format(config.data_dir): '/data/bshomes',
        '{0}/builds'.format(config.data_dir): '/data/builds',
        '{0}/ccache'.format(config.data_dir): '/data/ccache',
        '{0}/src'.format(config.data_dir): '/data/src:ro',
    }
    for vol in volumes:
        apply_acls(vol, buildbot_root_uid + BUILDBOT_UID, buildbot_root_gid + BUILDBOT_GID)
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return worker.DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image=util.Interpolate('workers/%(prop:workerimage)s'),
        masterFQDN=buildbot_ip,
        volumes=[':'.join((k,v)) for k, v in volumes.items()],
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )

for i in range(1, getattr(config, 'max_parallel_builds', 1) + 1):
    register('builder', StandardBuilderWorker('builder-{0}'.format(i)))

# The worker used for all preping stuff (fetching and triggering)
def FetcherWorker(name, **kwargs):
    volumes = {
        '{0}/src'.format(config.data_dir): '/data/src',
        '{0}/triggers'.format(config.data_dir): '/data/triggers',
    }
    for vol in volumes:
        apply_acls(vol, buildbot_root_uid + BUILDBOT_UID, buildbot_root_gid + BUILDBOT_GID)
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return worker.DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image='workers/{0}'.format(name),
        masterFQDN=buildbot_ip,
        volumes=[':'.join((k,v)) for k, v in volumes.items()],
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )
register('fetcher', FetcherWorker("fetcher"))
