from collections import defaultdict
from datetime import datetime, timedelta
import operator
import os
import re
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

    def __init__(self, base_dir, patches, command='patch -sZ -p1', **kwargs):
        self.base_dir = base_dir
        self.patches = patches
        self.command = command
        kwargs = self.setupShellMixin(kwargs, prohibitArgs=['command'])
        super().__init__(**kwargs)

    @defer.inlineCallbacks
    def run(self):
        terminate = False
        overall_result = util.SUCCESS
        for patch in self.patches:
            patch = os.path.join(self.base_dir, patch)
            # setup structures for reading the file
            try:
                with open(patch, 'rb') as fp:
                    patch_data = fp.read()
            except IOError:
                # if file does not exist, bail out with an error
                yield self.addCompleteLog('stderr',
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
        yield self.addCompleteLog('timestamps', log)

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

# Helper to generate file names
def create_names(buildname, platformname, archive_format, revision):
    if archive_format not in PACKAGE_FORMAT_COMMANDS:
        archive_format = "tar.bz2"
    if revision is not None:
        name = "{0}-{1}-{2}".format(platformname, buildname, revision[:8])
        archive = "{0}.{1}".format(name, archive_format)
    else:
        name = archive = ''
    symlink = "{0}-{1}-latest.{2}".format(platformname, buildname, archive_format)
    return name, archive, symlink

# Curly braces here are used by format not re
PACKAGE_NAME_RE = r'(?P<platform>{0})-(?P<build>{1})-(?P<revision>[0-9a-fA-F]*|latest)\..*'
# When both build and platform are None, detection will be wrong when builds have dashes
def parse_package_name(name, *, build = None, platform = None):
    if build is None:
        build = '[^-]+'
    if platform is None:
        platform = '.+'
    mtch = re.match(PACKAGE_NAME_RE.format(platform, build), name)
    return mtch

# Helper function which generates a list of steps that build the package on the worker,
# upload it to master and create the symlink for the latest
def get_package_steps(buildname, platformname, srcpath, dstpath, dsturl,
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

    def namesFromProps(props):
        return create_names(buildname, platformname, archive_format, props["revision"])

    @util.renderer
    def generateCommands(props):
        name, archive, _ = namesFromProps(props)
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
        name, _, _ = namesFromProps(props)

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
        _, archive, _ = namesFromProps(props)
        return archive

    @util.renderer
    def getMasterDest(props):
        _, archive, _ = namesFromProps(props)
        return os.path.join(dstpath, archive)

    @util.renderer
    def getArchiveURL(props):
        _, archive, _ = namesFromProps(props)
        return urlp.urljoin(dsturl, archive)

    @util.renderer
    def getLinkCommand(props):
        _, archive, symlink = namesFromProps(props)
        return "ln", "-sf", archive, os.path.join(dstpath, symlink)

    build_package = CleanShellSequence(
        name = "package",
        description = "packaging",
        descriptionDone = "package",
        doStepIf = doPackage,
        haltOnFailure = True,
        flunkOnFailure = True,
        commands = generateCommands,
        cleanup = generateCleanup,
        **kwargs
    )

    # dstpath will get created by FileUpload
    upload_package = steps.FileUpload(
        name = "upload package",
        description = "uploading",
        descriptionDone = "uploaded",
        doStepIf = doPackage,
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
        doStepIf = doPackage,
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

class CleanupSnapshots(steps.BuildStep):
    name = "cleanup old snapshots"
    renderables = [ 'dstpath', 'buildname', 'platformnames', 'keep_builds', 'obsolete', 'cleanup_unknown', 'dry_run' ]
    haltOnFailure = True
    flunkOnFailure = True

    def __init__(self,
            dstpath,
            buildname,
            platformnames,
            keep_builds = 14,
            obsolete = timedelta(days=30),
            cleanup_unknown = True,
            dry_run = False,
            **kwargs):
        super().__init__(**kwargs)

        self.dstpath = dstpath
        self.buildname = buildname
        self.platformnames = platformnames
        self.keep_builds = keep_builds
        self.obsolete = obsolete
        self.cleanup_unknown = cleanup_unknown
        self.dry_run = dry_run

    @defer.inlineCallbacks
    def run(self):
        to_clean = []
        latests = {}
        histories = defaultdict(list)

        log = yield self.addLog('log')

        yield log.addHeader("Cleaning directory {0}\nBuild: {1}\nPlatforms: {2}\n"
                "Keeping: {3} packages per platform\nObsolete after: {4}\n{5} unknown packages\n".format(
                    self.dstpath, self.buildname, ' '.join(self.platformnames), self.keep_builds, self.obsolete,
                    "Cleaning" if self.cleanup_unknown else "Not cleaning"))

        try:
            dir_iter = os.scandir(self.dstpath)
        except OSError as e:
            yield log.addStderr("An exception occurred while scanning the directory: {}\n".format(e))
            return util.FAILURE

        result = util.SUCCESS
        with dir_iter:
            for dir_entry in dir_iter:
                parsed = parse_package_name(dir_entry.name, build = self.buildname)

                if parsed is None:
                    if self.cleanup_unknown:
                        to_clean.append(dir_entry.path)
                    continue
                if parsed['build'] != self.buildname:
                    if self.cleanup_unknown:
                        to_clean.append(dir_entry.path)
                    continue

                if parsed['platform'] not in self.platformnames:
                    if self.cleanup_unknown:
                        to_clean.append(dir_entry.path)
                        # Here we try to apply our rules on outdated platforms
                        continue

                if parsed['revision'] == 'latest':
                    if parsed['platform'] not in self.platformnames:
                        # We remove latest symlink when platform is unknown
                        # We will keep packages during some time just in case
                        to_clean.append(dir_entry.path)
                        continue

                    if not dir_entry.is_symlink():
                        # Latest is not a symlink: that's fishy
                        to_clean.append(dir_entry.path)
                        continue

                    path = os.path.realpath(dir_entry.path)
                    if not os.path.isfile(path):
                        # Either a broken symlink, a directory(?), ...
                        to_clean.append(dir_entry.path)
                        continue

                    latests[parsed['platform']] = (dir_entry.path, path)
                    continue

                if not dir_entry.is_file(follow_symlinks=False):
                    # Not a file, fishy too
                    to_clean.append(dir_entry.path)
                    continue

                try:
                    stat_result = dir_entry.stat(follow_symlinks=False)
                    histories[parsed['platform']].append((dir_entry.path, datetime.fromtimestamp(stat_result.st_mtime)))
                except OSError as e:
                    yield log.addStderr("An exception occurred while stat()ing the file {}: {}\n".format(dir_entry.path, e))
                    result = util.WARNING
                    # File can't be stated: cleanup
                    to_clean.append(dir_entry.path)

        for platform, history in histories.items():
            # Sort by mtime, most recent first
            history.sort(key=operator.itemgetter(1), reverse=True)
            symlink, latest = latests.pop(platform, None)
            # Exclude N first files from cleaning: that's our history
            # If latest point at it, don't clean it too. That shouldn't, but in case.
            to_clean.extend(path for path, mtime in history[self.keep_builds:] if path != latest)
            # Cleanup obsolete remaining packages except latest
            obsolete = datetime.now() - self.obsolete
            to_clean.extend(path for path, mtime in history if path != latest and mtime < obsolete)

        for platform, (symlink, latest) in latests.items():
            # Those must be some valid symlink but not pointing at a recognized package: clean up symlink
            to_clean.append(symlink)

        to_clean.sort()

        removed = 0
        yield log.addStdout("Would clean:\n" if self.dry_run else "Cleaning:\n")
        for f in to_clean:
            yield log.addStdout('{0}\n'.format(f))
            try:
                if not self.dry_run:
                    os.remove(f)
                removed += 1
            except OSError as e:
                yield log.addStderr("An exception occurred while removing {}: {}\n".format(dir_entry.path, e))
                # We don't need specific test as we keep increasing error level
                result = util.FAILURE

        log.finish()
        self.descriptionDone = [("would have removed {0} files" if self.dry_run
            else "removed {0} files").format(removed)]

        return result
