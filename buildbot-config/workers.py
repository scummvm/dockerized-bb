import collections
import os
import random
import resource
import string

import docker

from buildbot.plugins import util

import builds
import config
import utils.worker

# Those are setup in docker images
BUILDBOT_UID, BUILDBOT_GID = 1000, 1000

workers = []
# This will contain lists of worker names by type for builds module
workers_by_type = collections.defaultdict(list)

def register(type_, worker):
    workers.append(worker)
    workers_by_type[type_].append(worker.name)

with docker.APIClient(base_url=config.docker_socket) as docker_client:
    if len(docker_client.networks(names=[config.docker_workers_net])) == 0:
        docker_client.create_network(config.docker_workers_net)

    buildbot_ip = docker_client.inspect_network(config.docker_workers_net)['IPAM']['Config'][0]['Gateway']

    utils.worker.setup_uid_gid(docker_client, BUILDBOT_UID, BUILDBOT_GID)

# To avoid performance issues soft limit the maximum number of files to a traditional value
# Still allow to go upper if needed by letting the process increase its value to our own limit
_, NOFILE_LIMIT_HARD = resource.getrlimit(resource.RLIMIT_NOFILE)
NOFILE_LIMIT_SOFT = 1024

# The worker used for all build stuff, image name depends on build property
def StandardBuilderWorker(name, **kwargs):
    volumes = [
        '{0}/bshomes:/data/bshomes'.format(config.data_dir),
        util.Interpolate('{0}/builds/%(prop:platformname)s/%(prop:buildname)s:/data/build'.format(config.data_dir)),
        '{0}/ccache:/data/ccache'.format(config.data_dir),
        util.Interpolate('{0}/src/%(prop:buildname)s:/data/src:ro'.format(config.data_dir)),
    ]
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    nofile_limit = docker.types.Ulimit(name='nofile', soft=NOFILE_LIMIT_SOFT, hard=NOFILE_LIMIT_HARD)
    return utils.worker.DockerWorker(name, password,
        docker_host=config.docker_socket,
        image=util.Interpolate('workers/%(prop:workerimage)s'),
        masterFQDN=buildbot_ip,
        volumes=volumes,
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
            'ulimits': [nofile_limit],
        },
        **kwargs
    )

for i in range(1, getattr(config, 'max_parallel_builds', 1) + 1):
    register('builder', StandardBuilderWorker('builder-{0}'.format(i)))

# The worker used for all preping stuff (fetching and triggering)
def FetcherWorker(name, **kwargs):
    volumes = [
        '{0}/src:/data/src'.format(config.data_dir),
        '{0}/triggers:/data/triggers'.format(config.data_dir),
    ]
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    nofile_limit = docker.types.Ulimit(name='nofile', soft=NOFILE_LIMIT_SOFT, hard=NOFILE_LIMIT_HARD)
    return utils.worker.DockerWorker(name, password,
        docker_host=config.docker_socket,
        image='workers/{0}'.format(name),
        masterFQDN=buildbot_ip,
        volumes=volumes,
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
            'ulimits': [nofile_limit],
        },
        **kwargs
    )
register('fetcher', FetcherWorker("fetcher"))
