import os, random, string

import docker
from buildbot.worker.docker import DockerLatentWorker as DockerLatentWorker
from buildbot.process.properties import Interpolate

import config

workers = []

def register(worker):
    workers.append(worker)

docker_client = docker.APIClient(base_url=config.docker_socket)
if len(docker_client.networks(names=[config.docker_workers_net])) == 0:
	docker_client.create_network(config.docker_workers_net)

buildbot_ip = docker_client.inspect_network(config.docker_workers_net)['IPAM']['Config'][0]['Gateway']

# Patch DockerLatentWorker to avoid bug with MRO and clear build properties when instance is deleted
if DockerLatentWorker.builds_may_be_incompatible == False:
    from buildbot.util.latent import CompatibleLatentWorkerMixin
    class DockerLatentWorker(DockerLatentWorker):
        builds_may_be_incompatible = True
        isCompatibleWithBuild = CompatibleLatentWorkerMixin.isCompatibleWithBuild

        def stop_instance(self, fast=False):
            d = super().stop_instance(fast)
            self._actual_build_props = None
            return d
assert(DockerLatentWorker.builds_may_be_incompatible == True)

def StandardBuilderWorker(name, **kwargs):
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image=Interpolate('workers/%(prop:workerimage)s'),
        masterFQDN=buildbot_ip,
        volumes=[
            '{0}/ccache:/data/ccache'.format(config.buildbot_data_dir),
            '{0}/src:/data/src:ro'.format(config.buildbot_data_dir),
            '{0}/builds:/data/builds'.format(config.buildbot_data_dir, name),
            '{0}/packages:/data/packages'.format(config.buildbot_data_dir),
        ],
        hostconfig={
            'network_mode': 'workers-net',
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )
register(StandardBuilderWorker("builder"))

def FetcherWorker(name, **kwargs):
    password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))
    tmpfs = docker.types.Mount('/tmp', None, type='tmpfs')
    return DockerLatentWorker(name, password,
        docker_host=config.docker_socket,
        image='workers/{0}'.format(name),
        masterFQDN=buildbot_ip,
        volumes=[
            '{0}/src:/data/src'.format(config.buildbot_data_dir),
            '{0}/triggers:/data/triggers'.format(config.buildbot_data_dir),
        ],
        hostconfig={
            'network_mode': 'workers-net',
            'read_only': True,
            'mounts': [tmpfs],
        },
        **kwargs
    )
register(FetcherWorker("fetcher"))
