import collections.abc
from datetime import timedelta
import multiprocessing
import os
import shutil
import sys
import urllib.parse as urlp

from buildbot.plugins import util
from buildbot.plugins import changes
from buildbot.plugins import schedulers
from buildbot.plugins import steps

from utils import scummsteps
import config
import workers

max_jobs = getattr(config, 'max_jobs', None) or (multiprocessing.cpu_count() + 1)

# Lock to avoid running more than 1 build at the same time on a worker
# This lock is used for builder workers to avoid too high CPU load
# It's also used for fetcher worker to ensure that fetching will occur just before building
# thanks to fetcher being locked all the way through the build process
lock_build = util.WorkerLock("worker", maxCount = 1)

# builds contains all build trees
# ccache is the cache for compiled objects used by ccache
# src contains the source trees
# triggers is some working directory needed by triggers
# bshomes is used for various build systems (like Gradle) to avoid downloading things at each run
# pollers is used by poll modules to maintain their state
for data_dir in ["builds", "ccache", "src", "triggers", "bshomes", "pollers" ]:
    os.makedirs(os.path.join(config.data_dir, data_dir), exist_ok=True)
shutil.copyfile(os.path.join(config.configuration_dir, "ccache.conf"),
    os.path.join(config.data_dir, "ccache", "ccache.conf"))

class Build:
    __slots__ = ['name']

    def __init__(self, name):
        self.name = name

    def getChangeSource(self, settings):
        pass

    def getGlobalSchedulers(self, platforms):
        pass

    def getGlobalBuilders(self, platforms):
        pass

    def getPerPlatformBuilders(self, platform):
        pass

class StandardBuild(Build):
    __slots__ = [
        'names',
        'baseurl', 'giturl', 'branch',
        'nightly', 'enable_force',
        'verbose_build',
        'description_',
        'lock_src']

    PATCHES = []
    DATA_FILES = []
    VERBOSE_BUILD_FLAG = None

    CONFIGURE_GENERATED_FILE = None

    def __init__(self, name, baseurl, branch, *,
            nightly = None, enable_force = True, giturl = None,
            verbose_build = False, description = None):
        super().__init__(name)
        if giturl is None:
            giturl = baseurl + ".git"
        self.baseurl = baseurl
        self.giturl = giturl
        self.branch = branch
        self.nightly = nightly
        self.enable_force = enable_force
        self.verbose_build = verbose_build
        self.description_ = description

        if self.CONFIGURE_GENERATED_FILE is None:
            raise Exception("Invalid CONFIGURE_GENERATED_FILE setting")

        # Lock used to avoid writing source code when it is read by another task
        self.lock_src = util.MasterLock("src-{0}".format(self.name), maxCount=sys.maxsize)
        self.buildNames()

    def buildNames(self):
        # Sort schedulers by definition order
        # Sort builder by type and definition order
        self.names = dict()
        # Pollers
        self.names['poller'] = "poller-{0}".format(self.name)
        # Schedulers
        self.names['sch-sb'] = "branch-scheduler-{0}".format(self.name)
        self.names['sch-nightly'] = "nightly-scheduler-{0}".format(self.name)
        self.names['sch-build'] = "build-scheduler-{0}".format(self.name)
        # Force schedulers
        # Force scheduler ID must begin with letter and not contain spaces
        self.names['sch-force-id-fetch'] = "force-fetch-{0}".format(self.name)
        self.names['sch-force-name-fetch'] = "Force fetch {0}".format(self.name)
        self.names['sch-force-id-build'] = "force-build-{0}".format(self.name)
        self.names['sch-force-name-build'] = "Force build".format(self.name)
        self.names['sch-force-id-clean'] = "force-clean-{0}".format(self.name)
        self.names['sch-force-name-clean'] = "Force clean {0} snapshots".format(self.name)
        # Builders
        self.names['bld-fetch'] = "fetch-{0}".format(self.name)
        self.names['bld-nightly'] = "nightly-{0}".format(self.name)
        # Put clean builders in last position
        self.names['bld-clean'] = "zzz_clean-{0}".format(self.name)
        # Platform builders
        builder_platform = "{0}-{{0}}".format(self.name)
        def get_platform_name(platforms):
            if isinstance(platforms, collections.abc.Iterable):
                return (builder_platform.format(platform.name) for platform in platforms)
            else:
                return builder_platform.format(platforms.name)

        self.names['bld-platform'] = get_platform_name

    @property
    def description(self):
        return self.description_ or self.name

    @description.setter
    def description(self, value):
        self.description_ = value

    def getChangeSource(self, settings):
        return changes.GitPoller(
            name=self.names['poller'],
            repourl=self.giturl,
            branches=[self.branch],
            workdir=os.path.join(config.data_dir, 'pollers', self.name),
            **settings)

    def getGlobalSchedulers(self, platforms):
        ret = list()
        change_filter = util.ChangeFilter(repository = [self.baseurl, self.giturl], branch = self.branch)

        # Fetch scheduler (triggered by event source)
        ret.append(schedulers.SingleBranchScheduler(name = self.names['sch-sb'],
                change_filter = change_filter,
                # Wait for 5 minutes before starting build
                treeStableTimer = 300,
                builderNames = [ self.names['bld-fetch'] ]))

        # Nightly scheduler (started by time)
        # It's triggered after regular builds to take note of the last fetched source
        # Note that build is not started by trigger
        # We cleanup after it because we just generated a new package
        if self.nightly is not None:
            ret.append(schedulers.NightlyTriggerable(name = self.names['sch-nightly'],
                branch = self.branch,
                builderNames = [ self.names['bld-nightly'], self.names['bld-clean'] ],
                hour = self.nightly[0],
                minute = self.nightly[1],
                onlyIfChanged = True))

        # All compiling builders
        comp_builders = list(self.names['bld-platform'](p for p in platforms if p.canBuild(self)))

        # Global build scheduler (triggered by fetch build and nightly build)
        ret.append(schedulers.Triggerable(name = self.names['sch-build'], builderNames = comp_builders))

        # Force schedulers
        if self.enable_force:
            ret.append(schedulers.ForceScheduler(name = self.names['sch-force-id-fetch'],
                buttonName=self.names['sch-force-name-fetch'],
                label=self.names['sch-force-name-fetch'],
                reason=util.StringParameter(name="reason", label="Reason:", required=True, size=80),
                builderNames = [ self.names['bld-fetch'] ],
                codebases = [util.CodebaseParameter(codebase='', hide=True)],
                properties = [
                    util.BooleanParameter(name="clean", label="Clean", default=False),
                    util.BooleanParameter(name="package", label="Package", default=False),
                    ]))
            ret.append(schedulers.ForceScheduler(name = self.names['sch-force-id-build'],
                buttonName=self.names['sch-force-name-build'],
                label=self.names['sch-force-name-build'],
                reason=util.StringParameter(name="reason", label="Reason:", required=True, size=80),
                builderNames = comp_builders,
                codebases = [util.CodebaseParameter(codebase='', hide=True)],
                properties = [
                    util.BooleanParameter(name="clean", label="Clean", default=False),
                    util.BooleanParameter(name="package", label="Package", default=False),
                    ]))
            ret.append(schedulers.ForceScheduler(name = self.names['sch-force-id-clean'],
                buttonName=self.names['sch-force-name-clean'],
                label=self.names['sch-force-name-clean'],
                reason=util.StringParameter(name="reason", hide=True),
                builderNames = [ self.names['bld-clean'] ],
                codebases = [util.CodebaseParameter(codebase='', hide=True)],
                properties = [
                    util.BooleanParameter(name="dry_run", label="Dry run", default=False),
                    ]))

        return ret

    def getGlobalBuilders(self, platforms):
        ret = list()

        f = util.BuildFactory()
        f.workdir = ""
        f.useProgress = False
        f.addStep(steps.Git(mode = "incremental",
            repourl = self.giturl,
            branch = self.branch,
            locks = [ self.lock_src.access("exclusive") ],
        ))
        if len(self.PATCHES):
            f.addStep(scummsteps.Patch(
                base_dir = config.configuration_dir,
                patches = self.PATCHES,
                locks = [ self.lock_src.access("exclusive") ],
            ))
        if self.nightly is not None:
            # Trigger nightly scheduler to let it know the source stamp
            f.addStep(steps.Trigger(name="Updating source stamp",
                schedulerNames = [ "nightly-scheduler-{0}".format(self.name) ],
                set_properties = {
                    'got_revision': util.Property('got_revision', defaultWhenFalse=False),
                },
                updateSourceStamp = True,
                hideStepIf=(lambda r, s: r == util.SUCCESS),
            ))
        f.addStep(steps.Trigger(name="Building all platforms",
            schedulerNames = [ self.names['sch-build'] ],
            set_properties = {
                'got_revision': util.Property('got_revision', defaultWhenFalse=False),
                'clean': util.Property('clean', defaultWhenFalse=False),
                'package': util.Property('package', defaultWhenFalse=False)
            },
            updateSourceStamp = True,
            waitForFinish = True))

        ret.append(util.BuilderConfig(
            name = self.names['bld-fetch'],
            workernames = workers.workers_by_type['fetcher'],
            workerbuilddir = "/data/src/{0}".format(self.name),
            factory = f,
            tags = ["fetch", self.name],
            locks = [ lock_build.access('counting') ],
        ))

        if self.nightly is not None:
            f = util.BuildFactory()
            f.addStep(steps.Trigger(name="Building all platforms",
                schedulerNames = [ self.names['sch-build'] ],
                updateSourceStamp = True,
                waitForFinish = True,
                set_properties = {
                    'got_revision': util.Property('got_revision', defaultWhenFalse=False),
                    'clean': True,
                    'package': True,
                    # Ensure our tag is put first and is split from the others
                    'owner': '  Nightly build  ',
                }))
            ret.append(util.BuilderConfig(
                name = self.names['bld-nightly'],
                # We use fetcher worker here as it will prevent building of other stuff like if a change had happened
                workernames = workers.workers_by_type['fetcher'],
                workerbuilddir = "/data/triggers/nightly-{0}".format(self.name),
                factory = f,
                tags = ["nightly", self.name],
                locks = [ lock_build.access('counting') ]
            ))

        snapshots_path = os.path.join(config.snapshots_dir, self.name)

        # Builder to clean packages
        f = util.BuildFactory()
        f.addStep(scummsteps.CleanupSnapshots(
            dstpath = snapshots_path,
            buildname = self.name,
            platformnames = [ platform.name
                for platform in platforms
                if platform.canPackage(self) ],
            dry_run = util.Property("dry_run", False),
            keep_builds = getattr(config, 'snapshots_keep_builds', 14),
            obsolete = timedelta(days=getattr(config, 'snapshots_obsolete_days', 30)),
            cleanup_unknown = getattr(config, 'snapshots_clean_unknown', True),
        ))
        ret.append(util.BuilderConfig(
            name = self.names['bld-clean'],
            workernames = workers.workers_by_type['fetcher'],
            workerbuilddir = "/data/triggers/cleanup-{0}".format(self.name),
            factory = f,
            tags = ["cleanup", self.name],
            locks = [ lock_build.access('counting') ]
        ))

        return ret

    def getPerPlatformBuilders(self, platform):
        if not platform.canBuild(self):
            return []

        # Don't use os.path.join as builder is a linux image
        src_path = "{0}/src/{1}".format("/data", self.name)
        configure_path = src_path + "/configure"
        build_path = "{0}/builds/{1}/{2}".format("/data", platform.name, self.name)

        # snapshots_path is used in Package step on master side
        snapshots_path = os.path.join(config.snapshots_dir, self.name)
        # Ensure last path component doesn't get removed here and in packaging step
        snapshots_url = urlp.urljoin(config.snapshots_url + '/', self.name + '/')

        env = platform.getEnv(self)

        f = util.BuildFactory()
        f.workdir = ""
        f.useProgress = False

        self.addCleanSteps(f, platform,
            env = env)

        self.addConfigureSteps(f, platform,
            configure_path=configure_path,
            env = env)

        self.addBuildSteps(f, platform,
            env = env)

        self.addTestsSteps(f, platform,
            env = env)

        self.addPackagingSteps(f, platform,
            env = env,
            src_path = src_path,
            snapshots_path = snapshots_path,
            snapshots_url = snapshots_url)

        locks = [ lock_build.access('counting'), self.lock_src.access("counting") ]
        if platform.lock_access:
            locks.append(platform.lock_access(self))

        return [util.BuilderConfig(
            name = self.names['bld-platform'](platform),
            workernames = workers.workers_by_type['builder'],
            workerbuilddir = build_path,
            factory = f,
            locks = locks,
            tags = ["build", self.name, platform.name],
            properties = {
                "platformname": platform.name,
                "workerimage": platform.getWorkerImage(self),
            },
        )]

    def addCleanSteps(self, f, platform, *, env):
        # Standard way of cleaning build directory (current working one)
        f.addStep(scummsteps.Clean(
            dir = "",
            doStepIf = util.Property("clean", False)
        ))

    def addConfigureSteps(self, f, platform, *,
            env, configure_path, additional_args=None):
        if additional_args is None:
            additional_args = []

        f.addStep(scummsteps.SetPropertyIfOlder(
            name = "check {0} freshness".format(self.CONFIGURE_GENERATED_FILE),
            src = configure_path,
            generated = self.CONFIGURE_GENERATED_FILE,
            property = "do_configure"
            ))

        command = [ configure_path ]
        command.extend(additional_args)
        if self.verbose_build and self.VERBOSE_BUILD_FLAG:
            command.append(self.VERBOSE_BUILD_FLAG)
        command.extend(platform.getConfigureArgs(self))

        f.addStep(steps.Configure(command = command,
            doStepIf = util.Property("do_configure", default=True, defaultWhenFalse=False),
            env = env))

    def addBuildSteps(self, f, platform, *, env, **kwargs):
        f.addStep(steps.Compile(command = [
                "make",
                "-j{0}".format(max_jobs)
            ],
            env = env,
            **kwargs))

    def addTestsSteps(self, f, platform, *, env, **kwargs):
        if not platform.canBuildTests(self):
            return

        if platform.canRunTests(self):
            f.addStep(steps.Test(env = env, **kwargs))
        else:
            # Compile Tests (Runner), but do not execute (as binary is non-native)
            f.addStep(steps.Test(command = [
                    "make",
                    "test/runner" ],
                env = env, **kwargs))

    def addPackagingSteps(self, f, platform, *, env,
        src_path, snapshots_path, snapshots_url):

        packaging_cmd = platform.getPackagingCmd(self)
        strip_cmd = platform.getStripCmd(self)

        # If there is a packaging command, no need to strip it would be done there
        if packaging_cmd is None and strip_cmd is not None:
            f.addStep(scummsteps.Strip(
                command = strip_cmd,
                env = env))

        if platform.canPackage(self):
            f.addSteps(scummsteps.get_package_steps(
                buildname = self.name,
                platformname = platform.name,
                srcpath = src_path,
                dstpath = snapshots_path,
                dsturl = snapshots_url,
                archive_format = platform.archiveext,
                disttarget = packaging_cmd,
                build_data_files = self.DATA_FILES,
                platform_data_files = platform.getDataFiles(self),
                platform_built_files = platform.getBuiltFiles(self),
                env = env))

class ScummVMBuild(StandardBuild):
    __slots__ = [ 'verbose_build' ]

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
        "dists/engine-data/fonts.dat",
        "dists/engine-data/hugo.dat",
        "dists/engine-data/kyra.dat",
        "dists/engine-data/lure.dat",
        "dists/engine-data/mort.dat",
        "dists/engine-data/neverhood.dat",
        "dists/engine-data/queen.tbl",
        "dists/engine-data/sky.cpt",
        "dists/engine-data/supernova.dat",
        "dists/engine-data/teenagent.dat",
        "dists/engine-data/titanic.dat",
        "dists/engine-data/tony.dat",
        "dists/engine-data/toon.dat",
        "dists/engine-data/ultima.dat",
        "dists/engine-data/wintermute.zip",
        "dists/engine-data/xeen.ccs",
        "dists/networking/wwwroot.zip",
        "dists/pred.dic",
        # Not in stable
        "dists/engine-data/cryo.dat",
        "dists/engine-data/macgui.dat",
        "dists/engine-data/macventure.dat",
        "dists/engine-data/myst3.dat",
        "dists/engine-data/grim-patch.lab",
        "dists/engine-data/monkey4-patch.m4b"
    ]
    VERBOSE_BUILD_FLAG = "--enable-verbose-build"
    CONFIGURE_GENERATED_FILE = "configure.stamp"

    def __init__(self, *args, **kwargs):
        verbose_build = kwargs.pop('verbose_build', False)

        super().__init__(*args, **kwargs)
        self.verbose_build = verbose_build

    def addConfigureSteps(self, *args, **kwargs):
        # Override to call parent with ScummVM specific configure arguments
        other_args = kwargs.pop('additional_args', [])
        additional_args = ["--enable-all-engines"]
        additional_args.extend(other_args)
        super().addConfigureSteps(*args, **kwargs, additional_args = additional_args)

    def addBuildSteps(self, *args, **kwargs):
        # ScummVM builds are longer
        timeout = kwargs.pop('timeout', 0)
        timeout = max(3600, timeout)
        super().addBuildSteps(*args, **kwargs, timeout = timeout)

class ScummVMStableBuild(ScummVMBuild):
    PATCHES = [
    ]

    # These settings must be updated when release is done
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
        "dists/engine-data/fonts.dat",
        "dists/engine-data/hugo.dat",
        "dists/engine-data/kyra.dat",
        "dists/engine-data/lure.dat",
        "dists/engine-data/mort.dat",
        "dists/engine-data/neverhood.dat",
        "dists/engine-data/queen.tbl",
        "dists/engine-data/sky.cpt",
        "dists/engine-data/supernova.dat",
        "dists/engine-data/teenagent.dat",
        "dists/engine-data/titanic.dat",
        "dists/engine-data/tony.dat",
        "dists/engine-data/toon.dat",
        "dists/engine-data/ultima.dat",
        "dists/engine-data/wintermute.zip",
        "dists/engine-data/xeen.ccs",
        "dists/networking/wwwroot.zip",
        "dists/pred.dic"
    ]
    CONFIGURE_GENERATED_FILE = "config.mk"

class ScummVMToolsBuild(StandardBuild):
    __slots__ = [ 'verbose_build' ]

    PATCHES = [
    ]

    DATA_FILES = [
        "COPYING",
        "NEWS",
        "README",
        "convert_dxa.sh",
        "convert_dxa.bat"
    ]
    VERBOSE_BUILD_FLAG = "--enable-verbose-build"
    CONFIGURE_GENERATED_FILE = "config.mk"

    def __init__(self, *args, **kwargs):
        verbose_build = kwargs.pop('verbose_build', False)

        super().__init__(*args, **kwargs)
        self.verbose_build = verbose_build

    def addTestsSteps(self, f, platform, *, env, **kwargs):
        # Don't do anything: we don't have tests of tools
        pass

builds = []

builds.append(ScummVMBuild("master", "https://github.com/scummvm/scummvm", "master", verbose_build=True, nightly=(4, 1), description="ScummVM latest"))
builds.append(ScummVMStableBuild("stable", "https://github.com/scummvm/scummvm", "branch-2-2", verbose_build=True, nightly=(4, 1), description="ScummVM stable"))
#builds.append(ScummVMBuild("gsoc2012", "https://github.com/digitall/scummvm", "gsoc2012-scalers-cont", verbose_build=True))
builds.append(ScummVMToolsBuild("tools-master", "https://github.com/scummvm/scummvm-tools", "master", verbose_build=True, nightly=(4, 1), description="ScummVM tools"))
