import os, sys

from buildbot.config import BuilderConfig
from buildbot.changes.filter import ChangeFilter
from buildbot.locks import MasterLock, WorkerLock
from buildbot.process import factory, results
from buildbot.process.properties import Property
from buildbot.scheduler import Triggerable
from buildbot.schedulers.timed import NightlyTriggerable
from buildbot.schedulers.basic import SingleBranchScheduler
from buildbot.schedulers.forcesched import ForceScheduler, CodebaseParameter, StringParameter, BooleanParameter
from buildbot.steps.source.git import Git
from buildbot.steps.trigger import Trigger
from buildbot.steps.shell import Configure, Compile, Test

import config
import steps

# Lock to avoid running more than 1 build at the same time on a worker
lock_build = WorkerLock("worker", maxCount = 1)

for data_dir in ["builds", "ccache", "packages", "src", "triggers", ]:
        os.makedirs(os.path.join(config.buildbot_data_dir, data_dir), exist_ok=True)

class Build:
    __slots__ = ['name']

    def __init__(self, name):
        self.name = name

    def getGlobalSchedulers(self, platforms):
        pass

    def getGlobalBuilders(self):
        pass

    def getPerPlatformBuilders(self, platform):
        pass

class StandardBuild(Build):
    __slots__ = ['baseurl', 'giturl', 'branch', 'nightly', 'enable_force', 'lock_src']

    PATCHES = []
    
    def __init__(self, name, baseurl, branch, nightly = None, enable_force = True, giturl = None):
        super().__init__(name)
        if giturl is None:
            giturl = baseurl + ".git"
        self.baseurl = baseurl
        self.giturl = giturl
        self.branch = branch
        self.nightly = nightly
        self.enable_force = enable_force
        # Lock used to avoid writing source code when it is read by another task
        self.lock_src = MasterLock("src-{0}".format(self.name), maxCount=sys.maxsize)

    def getGlobalSchedulers(self, platforms):
        ret = list()
        change_filter = ChangeFilter(repository = self.baseurl, branch = self.branch)

        # Fetch scheduler (triggered by event source)
        ret.append(SingleBranchScheduler(name = "fetch-{0}".format(self.name),
                change_filter = change_filter,
                treeStableTimer = 5,
                builderNames = [ "fetch-{0}".format(self.name) ]))

        # Nightly scheduler (started by time)
        # It's triggered after regular builds to take note of the last fetched source
        # Note that build is not started by trigger
        if self.nightly is not None:
            ret.append(NightlyTriggerable(name = "nightly-{0}".format(self.name),
                branch = self.branch,
                builderNames = [ "nightly-{0}".format(self.name) ],
                hour = self.nightly[0],
                minute = self.nightly[1],
                onlyIfChanged = True))

        # All compiling builders
        comp_builders = ["{0}-{1}".format(self.name, p.name) for p in platforms if p.canBuild(self)]
        
        # Global build scheduler (triggered by fetch build)
        ret.append(Triggerable(name = self.name, builderNames = comp_builders))

        # Force schedulers
        if self.enable_force:
            ret.append(ForceScheduler(name = "force-scheduler-{0}-fetch".format(self.name),
                reason=StringParameter(name="reason", label="Reason:", required=True, size=80),
                builderNames = [ "fetch-{0}".format(self.name) ],
                codebases = [CodebaseParameter(codebase='', hide=True)],
                properties = [
                    BooleanParameter(name="clean", label="Clean", default=False),
                    BooleanParameter(name="package", label="Package", default=False),
                    ]))
            ret.append(ForceScheduler(name = "force-scheduler-{0}-build".format(self.name),
                reason=StringParameter(name="reason", label="Reason:", required=True, size=80),
                builderNames = comp_builders,
                codebases = [CodebaseParameter(codebase='', hide=True)],
                properties = [
                    BooleanParameter(name="clean", label="Clean", default=False),
                    BooleanParameter(name="package", label="Package", default=False),
                    ]))

        return ret

    def getGlobalBuilders(self):
        ret = list()

        f = factory.BuildFactory()
        f.useProgress = False
        f.addStep(Git(mode = "incremental",
            workdir = ".",
            repourl = self.giturl,
            branch = self.branch,
            locks = [ self.lock_src.access("exclusive") ],
        ))
        if len(self.PATCHES):
            f.addStep(steps.Patch(patches = self.PATCHES,
                workdir = ".",
                locks = [ self.lock_src.access("exclusive") ],
            ))
        if self.nightly is not None:
            # Trigger nightly scheduler to let it know the source stamp
            f.addStep(Trigger(name="Updating source stamp", hideStepIf=(lambda r, s: r == results.SUCCESS),
                schedulerNames = [ "nightly-{0}".format(self.name) ]))
        f.addStep(Trigger(name="Building all platforms", schedulerNames = [ self.name ],
                            copy_properties = [ 'got_revision', 'clean', 'package' ],
                            updateSourceStamp = True,
                            waitForFinish = True))

        ret.append(BuilderConfig(
            name = "fetch-{0}".format(self.name),
            # This is specific
            workername = 'fetcher',
            workerbuilddir = "/data/src/{0}".format(self.name),
            factory = f,
            tags = ["fetch"],
        ))

        if self.nightly is not None:
            f = factory.BuildFactory()
            f.addStep(Trigger(schedulerNames = [ self.name ],
                copy_properties = [ 'got_revision' ],
                updateSourceStamp = True,
                waitForFinish = True,
                set_properties = {
                    'clean': True,
                    'package': True }))

            ret.append(BuilderConfig(
                name = "nightly-{0}".format(self.name),
                # TODO: Fix this
                workername = 'fetcher',
                workerbuilddir = "/data/triggers/nightly-{0}".format(self.name),
                factory = f,
                tags = ["nightly"],
                locks = [ self.lock_src.access("counting") ]
            ))

        return ret

class ScummVMBuild(StandardBuild):
    __slots__ = [ 'data_files', 'verbose_build' ]

    PATCHES = [
    ]

    DATA_FILES = [
        "AUTHORS",
        "COPYING",
        "COPYING.LGPL",
        "COPYING.BSD",
        "COPYRIGHT",
        "NEWS.md",
        "README.md",
        "gui/themes/translations.dat",
        "gui/themes/scummclassic.zip",
        "gui/themes/scummmodern.zip",
        "gui/themes/scummremastered.zip",
        "dists/engine-data/access.dat",
        "dists/engine-data/cryomni3d.dat",
        "dists/engine-data/drascula.dat",
        "dists/engine-data/hugo.dat",
        "dists/engine-data/kyra.dat",
        "dists/engine-data/lure.dat",
        "dists/engine-data/mort.dat",
        "dists/engine-data/neverhood.dat",
        "dists/engine-data/queen.tbl",
        "dists/engine-data/sky.cpt",
        "dists/engine-data/teenagent.dat",
        "dists/engine-data/tony.dat",
        "dists/engine-data/toon.dat",
        "dists/engine-data/wintermute.zip",
        "dists/networking/wwwroot.zip",
        "dists/pred.dic"
    ]

    def __init__(self, *args, **kwargs):
        verbose_build = kwargs.get('verbose_build', False)
        kwargs.pop('verbose_build', None)
        data_files = kwargs.get('data_files', None)
        kwargs.pop('data_files', None)

        super().__init__(*args, **kwargs)
        self.verbose_build = verbose_build
        if data_files is None:
            data_files = self.DATA_FILES
        self.data_files = data_files

    def getPerPlatformBuilders(self, platform):
        if not platform.canBuild(self):
            return []

        src_path = "{0}/src/{1}".format(platform.workerdatapath, self.name)
        configure_path = src_path + "/configure"
        build_path = "{0}/builds/{1}/{2}".format(platform.workerdatapath, platform.name, self.name)
        packages_path = "{0}/packages/snapshots/{1}".format(platform.workerdatapath, self.name)

        env = platform.getEnv(self)

        f = factory.BuildFactory()
        f.useProgress = False

        f.addStep(steps.Clean(
            dir = "",
            doStepIf = Property("clean", False)
        ))

        f.addStep(steps.SetPropertyIfOlder(
            name = "check config.mk freshness",
            src = configure_path,
            generated = "config.mk",
            property = "do_configure"
            ))

        if self.verbose_build:
            platform_build_verbosity = "--enable-verbose-build"
        else:
            platform_build_verbosity = ""

        f.addStep(Configure(command = [
                configure_path,
                "--enable-all-engines",
                "--disable-engine=testbed",
                platform_build_verbosity
            ] + platform.getConfigureArgs(self),
            doStepIf = Property("do_configure", default=True, defaultWhenFalse=False),
            env = env))

        f.addStep(Compile(command = [
                "make",
                "-j5"
            ],
            env = env))

        if platform.canBuildTests(self):
            if platform.run_tests:
                f.addStep(Test(env = env))
            else:
                # Compile Tests (Runner), but do not execute (as binary is non-native)
                f.addStep(Test(command = [
                        "make",
                        "test/runner" ],
                    env = env))

        packaging_cmd = None
        if platform.getPackagingCmd(self) is not None:
            packaging_cmd = platform.getPackagingCmd(self)
        else:
            if platform.getStripCmd(self) is not None:
                f.addStep(steps.Strip(command = platform.getStripCmd()))

        if platform.canPackage(self):
            f.addStep(steps.Package(disttarget = packaging_cmd,
                                    srcpath = src_path,
                                    dstpath = packages_path,
                                    data_files = self.data_files,
                                    buildname = "{0}-{1}".format(platform.name, self.name),
                                    platform_built_files = platform.getBuiltFiles(self),
                                    platform_data_files = platform.getDataFiles(self),
                                    archive_format = platform.archiveext,
                                    env = env))

        return [BuilderConfig(
            name = "{0}-{1}".format(self.name, platform.name),
            workername = platform.workername,
            workerbuilddir = build_path,
            factory = f,
            locks = [ lock_build.access('counting'), self.lock_src.access("counting") ],
            tags = [self.name],
            properties = {
                "platformname": platform.name,
                "workerimage": platform.workerimage,
            },
        )]

class ScummVMStableBuild(ScummVMBuild):
    PATCHES = [
        "./patches/fix-devkitppc.patch",
    ]

class ScummVMToolsBuild(StandardBuild):
    __slots__ = [ 'data_files', 'verbose_build' ]

    DATA_FILES = [
        "COPYING",
        "NEWS",
        "README",
        "convert_dxa.sh",
        "convert_dxa.bat"
    ]

    def __init__(self, *args, **kwargs):
        verbose_build = kwargs.get('verbose_build', False)
        kwargs.pop('verbose_build', None)
        data_files = kwargs.get('data_files', None)
        kwargs.pop('data_files', None)

        super().__init__(*args, **kwargs)
        self.verbose_build = verbose_build
        if data_files is None:
            data_files = self.DATA_FILES
        self.data_files = data_files

    def getPerPlatformBuilders(self, platform):
        if not platform.canBuild(self):
            return []

        src_path = "{0}/src/{1}".format(platform.workerdatapath, self.name)
        configure_path = src_path + "/configure"
        build_path = "{0}/builds/{1}/{2}".format(platform.workerdatapath, platform.name, self.name)
        packages_path = "{0}/packages/snapshots/{1}".format(platform.workerdatapath, self.name)

        env = platform.getEnv(self)

        f = factory.BuildFactory()
        f.useProgress = False
        
        f.addStep(steps.Clean(
            dir = "",
            doStepIf = Property("clean", False)
        ))

        f.addStep(steps.SetPropertyIfOlder(
            name = "check config.mk freshness",
            src = configure_path,
            generated = "config.mk",
            property = "do_configure"
            ))

        if self.verbose_build:
            platform_build_verbosity = "--enable-verbose-build"
        else:
            platform_build_verbosity = ""

        f.addStep(Configure(command = [
                configure_path,
                platform_build_verbosity
            ] + platform.getConfigureArgs(self),
            doStepIf = Property("do_configure", default=True, defaultWhenFalse=False),
            env = env))

        f.addStep(Compile(command = [
                "make",
                "-j5"
            ],
            env = env))

        # No tests

        packaging_cmd = None
        if platform.getPackagingCmd(self) is not None:
            packaging_cmd = platform.getPackagingCmd(self)
        else:
            if platform.getStripCmd(self) is not None:
                f.addStep(steps.Strip(command = platform.getStripCmd()))

        if platform.canPackage(self):
            f.addStep(steps.Package(disttarget = packaging_cmd,
                                    srcpath = src_path,
                                    dstpath = packages_path,
                                    data_files = self.data_files,
                                    buildname = "{0}-{1}".format(platform.name, self.name),
                                    platform_built_files = platform.getBuiltFiles(self),
                                    platform_data_files = platform.getDataFiles(self),
                                    archive_format = platform.archiveext,
                                    env = env))

        return [BuilderConfig(
            name = "{0}-{1}".format(self.name, platform.name),
            workername = platform.workername,
            workerbuilddir = build_path,
            factory = f,
            locks = [ lock_build.access('counting'), self.lock_src.access("counting") ],
            tags = [self.name],
            properties = {
                "platformname": platform.name,
                "workerimage": platform.workerimage,
            },
        )]

builds = []

builds.append(ScummVMBuild("master", "https://github.com/scummvm/scummvm", "master", verbose_build=True, nightly=(4, 1)))
builds.append(ScummVMBuild("stable", "https://github.com/scummvm/scummvm", "eaa487fcd442c78c8949e225627b632a8c52df9a", verbose_build=True, nightly=(4, 1)))
#builds.append(ScummVMStableBuild("stable", "https://github.com/scummvm/scummvm", "branch-2-1", verbose_build=True, nightly=(4, 1)))
#builds.append(ScummVMBuild("gsoc2012", "https://github.com/digitall/scummvm", "gsoc2012-scalers-cont", verbose_build=True))
builds.append(ScummVMToolsBuild("tools-master", "https://github.com/scummvm/scummvm-tools", "master", verbose_build=True, nightly=(4, 1)))
