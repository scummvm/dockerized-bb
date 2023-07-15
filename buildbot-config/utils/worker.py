import os

from twisted.internet import defer

from buildbot.plugins import worker
from buildbot.util import runprocess

buildbot_uid = 0
buildbot_gid = 0

## Helper to determine uid:gid used by docker
def setup_uid_gid(client, worker_uid, worker_gid):
    global buildbot_uid, buildbot_gid

    def get_root_uid_gid():
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

    root_uid, root_gid = get_root_uid_gid()
    buildbot_uid = root_uid + worker_uid
    buildbot_gid = root_gid + worker_uid

# Helper to create volumes on demand and setup correct ACLs
class DockerWorker(worker.DockerLatentWorker):
    @defer.inlineCallbacks
    def start_instance(self, build):
        volumes = yield build.render(self.volumes)
        for volume_string in (volumes or []):
            try:
                bind, dst_mode = volume_string.split(":", 1)
            except ValueError:
                continue
            # Don't try to apply ACLs or create dirs on read-only mounts
            # They must have been applied earlier
            try:
                dst, mode = dst_mode.split(":", 1)
                if mode == "ro":
                    continue
            except ValueError:
                # No : so no ro
                pass
            os.makedirs(bind, exist_ok=True)
            self.apply_acls(bind)
        res = yield super().start_instance(build)

        return res

    @defer.inlineCallbacks
    def apply_acls(self, bind):
        for cmd in [["setfacl", "-m", "user:{0}:rwx".format(buildbot_uid), bind],
                ["setfacl", "-m", "group:{0}:rwx".format(buildbot_gid), bind]]:
            rc, out, err = yield runprocess.run_process(self.master.reactor, cmd, env=None,
                                                        collect_stdout=True,
                                                        collect_stderr=True)
            if rc != 0:
                raise RuntimeError("setfacl '{0}' failed with result {1}:\n{2}".format(cmd, rc, err))


