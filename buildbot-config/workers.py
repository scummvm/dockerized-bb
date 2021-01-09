import os, random, string

import docker

from buildbot.plugins import util
from buildbot.plugins import worker

import config

workers = []

def register(worker):
    workers.append(worker)

docker_client = docker.APIClient(base_url=config.docker_socket)
if len(docker_client.networks(names=[config.docker_workers_net])) == 0:
	docker_client.create_network(config.docker_workers_net)

buildbot_ip = docker_client.inspect_network(config.docker_workers_net)['IPAM']['Config'][0]['Gateway']

def StandardBuilderWorker(name, **kwargs):
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return worker.DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image=util.Interpolate('workers/%(prop:workerimage)s'),
        masterFQDN=buildbot_ip,
        volumes=[
            '{0}/ccache:/data/ccache'.format(config.data_dir),
            '{0}/src:/data/src:ro'.format(config.data_dir),
            '{0}/builds:/data/builds'.format(config.data_dir),
            '{0}/bshomes:/data/bshomes'.format(config.data_dir),
        ],
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )
register(StandardBuilderWorker("builder"))

def FetcherWorker(name, **kwargs):
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return worker.DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image='workers/{0}'.format(name),
        masterFQDN=buildbot_ip,
        volumes=[
            '{0}/src:/data/src'.format(config.data_dir),
            '{0}/triggers:/data/triggers'.format(config.data_dir),
        ],
        hostconfig={
            'network_mode': config.docker_workers_net,
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )
register(FetcherWorker("fetcher"))
