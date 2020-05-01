import os
from datetime import datetime

from twisted.internet import defer

from buildbot.process.properties import Property, renderer
from buildbot.process import buildstep, results
from buildbot.process import remotecommand

from buildbot.steps.shell import ShellCommand
from buildbot.steps.shellsequence import ShellSequence, ShellArg
from buildbot.steps.worker import RemoveDirectory

class Patch(buildstep.ShellMixin, buildstep.BuildStep):
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
        overall_result = results.SUCCESS
        for patch in self.patches:
            # setup structures for reading the file
            try:
                with open(patch, 'rb') as fp:
                    patch_data = fp.read()
            except IOError:
                # if file does not exist, bail out with an error
                self.addCompleteLog('stderr',
                                    'File %r not available at master' % source)
                return results.FAILURE
            cmd = yield self.makeRemoteShellCommand(command=self.command,
                    initialStdin=patch_data)
            yield self.runCommand(cmd)

            overall_result, terminate = results.computeResultAndTermination(
                self, cmd.results(), overall_result)
            if terminate:
                break

        if overall_result == results.SUCCESS:
            self.descriptionDone = ["patched"]
        return overall_result



# buildstep class to determine if a file is newer than another one
class SetPropertyIfOlder(buildstep.BuildStep):
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
            return results.FAILURE

        if statGenerated.didFail():
            # No generated file: set property to True
            self.setProperty(self.property, True, self.name)
            self.descriptionDone = ["generated file not found."]
            return results.SUCCESS

        # stat object is lost when marshalling and result is seen as a tuple, doc says st_mtime is eighth
        dateSrc = statSrc.updates["stat"][-1][8]
        dateGenerated = statGenerated.updates["stat"][-1][8]

        log = "{0}: {1!s}\n".format(self.src, datetime.fromtimestamp(dateSrc))
        log += "{0}: {1!s}\n".format(self.generated, datetime.fromtimestamp(dateGenerated))
        self.addCompleteLog('timestamps', log)

        # Set to True if older
        self.setProperty(self.property, dateGenerated <= dateSrc, self.name)
        self.descriptionDone = ["generated file is {0} than source file".format("older" if dateGenerated <= dateSrc else "newer")]
        return results.SUCCESS

# buildstep class to strip binaries, only done on nightly builds.
def Strip(command, **kwargs):
    return ShellCommand(
        name = "strip",
        description = "stripping",
        descriptionDone = "strip",
        command = command,
        doStepIf = Property("package", default=False),
        **kwargs)

# buildstep class to execute cleanup commands even if main commands failed
class CleanShellSequence(ShellSequence):
    renderables = ['cleanup']

    def __init__(self, cleanup, **kwargs):
        self.cleanup = cleanup
        super().__init__(**kwargs)

    @defer.inlineCallbacks
    def run(self):
        result = yield self.runShellSequence(self.commands)
        yield self.runShellSequence(self.cleanup)
        return result

    def getResultSummary(self):
        return buildstep.BuildStep.getResultSummary(self)

PACKAGE_FORMAT_COMMANDS = {
    # format: [command, options]
    "tar.bz2": ["tar", "cvjf"],
    "tar.gz": ["tar", "cvzf"],
    "tar.xz": ["tar", "cvJf"],
    "zip": ["zip", "-r"],
}

def Package(disttarget, srcpath, dstpath, data_files,
        buildname, platform_built_files, platform_data_files, archive_format, 
        **kwargs):
    files = []
    # dont pack up the default files if the port has its own dist target
    if not disttarget:
        files += [ os.path.join(srcpath, f) for f in data_files ]
    files += platform_built_files
    files += [ os.path.join(srcpath, f) for f in platform_data_files ]

    @renderer
    def generateCommands(props):
        # Create a mutable variable from the outer one
        archive_format_ = archive_format
        if archive_format_ not in PACKAGE_FORMAT_COMMANDS:
            archive_format_ = "tar.bz2"

        name = "{0}-{1}".format(buildname, props["revision"][:8])
        archive = "{0}.{1}".format(name, archive_format_)
        symlink = "{0}-latest.{1}".format(buildname, archive_format_)

        archive_command = PACKAGE_FORMAT_COMMANDS.get(archive_format_) + [archive, name+"/"]

        commands = []

        if disttarget:
            commands.append(ShellArg(["make", disttarget],
                    logfile="make", haltOnFailure=True))

        commands.append(ShellArg(["mkdir", name],
            logfile="stdio", haltOnFailure=True))
        # Use a string for cp to allow shell globbing
        # WARNING: files aren't surrounded with quotes to let it happen
        commands.append(ShellArg('cp -r ' + ' '.join(files) + ' "{0}/"'.format(name),
            logfile="stdio", haltOnFailure=True))
        commands.append(ShellArg(archive_command,
            logfile="stdio", haltOnFailure=True))
        commands.append(ShellArg(["chmod", "644", archive],
            logfile="stdio", haltOnFailure=True))
        commands.append(ShellArg(["mkdir", "-p", dstpath+"/"],
            logfile="stdio", haltOnFailure=True))
        commands.append(ShellArg(["mv", archive, dstpath+"/"],
            logfile="stdio", haltOnFailure=True))
        commands.append(ShellArg(["ln", "-sf", archive, os.path.join(dstpath, symlink)],
            logfile="stdio", haltOnFailure=True))

        return commands

    @renderer
    def generateCleanup(props):
        name = "{0}-{1}".format(buildname, props["revision"][:8])

        commands = []
        commands.append(ShellArg(["rm", "-rf", name],
            haltOnFailure=True))
        return commands

    @renderer
    def doPackage(props):
        return (
                "revision" in props and props["revision"] is not None and
                "package" in props and props["package"])

    return CleanShellSequence(
        name = "package",
        description = [ "packaging" ],
        descriptionDone = [ "package" ],
        haltOnFailure = True,
        flunkOnFailure = True,
        commands = generateCommands,
        cleanup = generateCleanup,
        doStepIf = doPackage,
        **kwargs
    )

# buildstep class to wipe all build folders (eg "trunk-*")
def Clean(**kwargs):
    return RemoveDirectory(
        name = "clean",
        description = "cleaning",
        descriptionDone = "clean",
        **kwargs)
