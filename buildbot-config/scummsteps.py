import os
from datetime import datetime
import urllib.parse as urlp

from twisted.internet import defer

from buildbot.plugins import util
from buildbot.plugins import steps

# Kept for buildstep.ShellMixin and results.computeResultAndTermination
from buildbot.process import buildstep, results
# Kept for remotecommand.RemoteCommand
from buildbot.process import remotecommand

class Patch(buildstep.ShellMixin, steps.BuildStep):
    name = "patch"
    renderables = [ 'patches', 'command' ]
    haltOnFailure = True
    flunkOnFailure = True

    def __init__(self, patches, command='patch -sZ -p1', **kwargs):
        self.patches = patches
        self.command = command
        kwargs = self.setupShellMixin(kwargs, prohibitArgs=['command'])
        super().__init__(**kwargs)

    @defer.inlineCallbacks
    def run(self):
        terminate = False
        overall_result = util.SUCCESS
        for patch in self.patches:
            patch = os.path.join(config.config_dir, patch)
            # setup structures for reading the file
            try:
                with open(patch, 'rb') as fp:
                    patch_data = fp.read()
            except IOError:
                # if file does not exist, bail out with an error
                self.addCompleteLog('stderr',
                                    'File %r not available at master' % source)
                return util.FAILURE
            cmd = yield self.makeRemoteShellCommand(command=self.command,
                    initialStdin=patch_data)
            yield self.runCommand(cmd)

            overall_result, terminate = results.computeResultAndTermination(
                self, cmd.results(), overall_result)
            if terminate:
                break

        if overall_result == util.SUCCESS:
            self.descriptionDone = ["patched"]
        return overall_result

# buildstep class to determine if a file is newer than another one
class SetPropertyIfOlder(steps.BuildStep):
    name = "set property if older"
    renderables = ['src', 'generated', 'workdir' ]
    haltOnFailure = True
    flunkOnFailure = True

    def __init__(self,
            src, generated,
            property,
            workdir=None,
            **kwargs):
        super().__init__(**kwargs)

        self.src = src
        self.generated = generated
        self.property = property
        self.workdir = workdir

    @defer.inlineCallbacks
    def run(self):
        self.checkWorkerHasCommand('stat')
        statSrc = remotecommand.RemoteCommand('stat',
                {'workdir': self.workdir,
                    'file': self.src})
        statGenerated = remotecommand.RemoteCommand('stat',
                {'workdir': self.workdir,
                    'file': self.generated})

        yield self.runCommand(statSrc)
        yield self.runCommand(statGenerated)

        if statSrc.didFail():
            # Uh oh: without source no generation
            self.descriptionDone = ["source file not found."]
            return util.FAILURE

        if statGenerated.didFail():
            # No generated file: set property to True
            self.setProperty(self.property, True, self.name)
            self.descriptionDone = ["generated file not found."]
            return util.SUCCESS

        # stat object is lost when marshalling and result is seen as a tuple, doc says st_mtime is eighth
        dateSrc = statSrc.updates["stat"][-1][8]
        dateGenerated = statGenerated.updates["stat"][-1][8]

        log = "{0}: {1!s}\n".format(self.src, datetime.fromtimestamp(dateSrc))
        log += "{0}: {1!s}\n".format(self.generated, datetime.fromtimestamp(dateGenerated))
        self.addCompleteLog('timestamps', log)

        # Set to True if older
        self.setProperty(self.property, dateGenerated <= dateSrc, self.name)
        self.descriptionDone = ["generated file is {0} than source file".format("older" if dateGenerated <= dateSrc else "newer")]
        return util.SUCCESS

# buildstep class to strip binaries, only done on nightly builds.
def Strip(command, **kwargs):
    return steps.ShellCommand(
        name = "strip",
        description = "stripping",
        descriptionDone = "strip",
        command = command,
        doStepIf = util.Property("package", default=False),
        **kwargs)

# buildstep class to execute cleanup commands even if main commands failed
class CleanShellSequence(steps.ShellSequence):
    renderables = ['cleanup']

    def __init__(self, cleanup, **kwargs):
        self.cleanup = cleanup
        super().__init__(**kwargs)

    @defer.inlineCallbacks
    def run(self):
        result = yield self.runShellSequence(self.commands)
        # Backup the last command run in normal steps to restore it after cleanup
        # This ensures summary won't be polluted by the cleanup commands
        command = self.command
        yield self.runShellSequence(self.cleanup)
        self.command = command
        return result

PACKAGE_FORMAT_COMMANDS = {
    # format: [command, options]
    "tar.bz2": ["tar", "cvjf"],
    "tar.gz": ["tar", "cvzf"],
    "tar.xz": ["tar", "cvJf"],
    "zip": ["zip", "-r"],
}

# Helper function which generates a list of steps that build the package on the worker,
# upload it to master and create the symlink for the latest
def get_package_steps(buildname, srcpath, dstpath, dsturl,
        archive_format, disttarget,
        build_data_files, platform_data_files,
        platform_built_files,
        **kwargs):
    if archive_format not in PACKAGE_FORMAT_COMMANDS:
        archive_format = "tar.bz2"
    archive_base_command = PACKAGE_FORMAT_COMMANDS.get(archive_format)

    files = []

    files += platform_built_files
    # If file is absolute or begins with a $ (environment variable) don't prepend srcpath
    if platform_data_files:
        files += [ f if (os.path.isabs(f) or f[0:1] == '$') else os.path.join(srcpath, f)
                for f in platform_data_files ]
    # dont pack up the default files if the port has its own dist target
    if not disttarget:
        files += [ os.path.join(srcpath, f) for f in build_data_files ]

    def createNames(props):
        name = "{0}-{1}".format(buildname, props["revision"][:8])
        archive = "{0}.{1}".format(name, archive_format)
        symlink = "{0}-latest.{1}".format(buildname, archive_format)
        return name, archive, symlink

    @util.renderer
    def generateCommands(props):
        name, archive, _ = createNames(props)
        archive_full_command = archive_base_command + [archive, name+"/"]

        commands = []

        if disttarget:
            commands.append(util.ShellArg(["make", disttarget],
                    logname="make {0}".format(disttarget), haltOnFailure=True))

        commands.append(util.ShellArg(["mkdir", name],
            logname="archive", haltOnFailure=True))
        # Use a string for cp to allow shell globbing
        # WARNING: files aren't surrounded with quotes to let it happen
        commands.append(util.ShellArg('cp -r ' + ' '.join(files) + ' "{0}/"'.format(name),
            logname="archive", haltOnFailure=True))
        commands.append(util.ShellArg(archive_full_command,
            logname="archive", haltOnFailure=True))

        return commands

    @util.renderer
    def generateCleanup(props):
        name, _, _ = createNames(props)

        commands = []
        commands.append(util.ShellArg(["rm", "-rf", name],
            logname="cleanup", haltOnFailure=True))
        return commands

    @util.renderer
    def doPackage(props):
        return ("revision" in props and
                "package" in props and
                props["revision"] is not None and
                bool(props["package"]))

    @util.renderer
    def getWorkerSrc(props):
        _, archive, _ = createNames(props)
        return archive

    @util.renderer
    def getMasterDest(props):
        _, archive, _ = createNames(props)
        return os.path.join(dstpath, archive)

    @util.renderer
    def getArchiveURL(props):
        _, archive, _ = createNames(props)
        return urlp.urljoin(dsturl, archive)

    @util.renderer
    def getLinkCommand(props):
        _, archive, symlink = createNames(props)
        return "ln", "-sf", archive, os.path.join(dstpath, symlink)

    build_package = CleanShellSequence(
        name = "package",
        description = "packaging",
        descriptionDone = "package",
        haltOnFailure = True,
        flunkOnFailure = True,
        commands = generateCommands,
        cleanup = generateCleanup,
        doStepIf = doPackage,
        **kwargs
    )

    # dstpath will get created by FileUpload
    upload_package = steps.FileUpload(
        name = "upload package",
        description = "uploading",
        descriptionDone = "uploaded",
        haltOnFailure = True,
        flunkOnFailure = True,
        workersrc = getWorkerSrc,
        masterdest = getMasterDest,
        mode = 0o0644,
        url = getArchiveURL if dsturl else None)
    link = steps.MasterShellCommand(
        name = "link latest snapshot",
        description = "linking",
        descriptionDone = "linked",
        haltOnFailure = True,
        flunkOnFailure = True,
        command = getLinkCommand,
        env = {})

    return build_package, upload_package, link

# buildstep class to wipe all build folders (eg "trunk-*")
def Clean(**kwargs):
    return steps.RemoveDirectory(
        name = "clean",
        description = "cleaning",
        descriptionDone = "clean",
        **kwargs)
