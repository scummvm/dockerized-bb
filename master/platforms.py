import copy
import os

import config
import builds
import workers

def _getFromBuild(data, build):
    if type(data) is not dict:
        return data
    if len(data) == 0:
        return None
    if build.name in data:
        return data[build.name]
    for cls in type(build).mro():
        if cls in data:
            return data[cls]
    if None in data:
        return data[None]
    
def _buildInData(data, build):
    if data is None:
        return True
    if len(data) == 0:
        return None
    if build.name in data:
        return True
    for cls in type(build).mro():
        if cls in data:
            return True
    return False

class Platform:
    __slots__ = ['name', 'compatibleBuilds', 
            'env', 'buildenv',
            'configureargs', 'buildconfigureargs',
            'packageable', 'built_files', 'data_files',
            'packaging_cmd', 'strip_cmd', 'archiveext',
            'testable', 'run_tests',
            'workername', 'workerimage', 'workerdatapath']

    def __init__(self, name):
        self.name = name
        self.compatibleBuilds = None
        self.env = copy.deepcopy(config.common_env)
        self.buildenv = {}
        self.configureargs = []
        self.buildconfigureargs = {}
        self.packageable = True
        self.built_files = []
        self.data_files = []
        self.packaging_cmd = None
        self.strip_cmd = None
        self.archiveext = "tar.xz"
        # Can build tests
        self.testable = True
        # Can run tests
        self.run_tests = False

        self.workername = "builder"
        self.workerimage = name
        self.workerdatapath = "/data/"

    def canBuild(self, build):
        return _buildInData(self.compatibleBuilds, build)
    def getEnv(self, build):
        ret = dict(self.env)
        add = _getFromBuild(self.buildenv, build)
        if add is not None:
            ret.update(add)
        return ret
    def getConfigureArgs(self, build):
        ret = list(self.configureargs)
        add = _getFromBuild(self.buildconfigureargs, build)
        if add is not None:
            ret.extend(add)
        return ret
    def canPackage(self, build):
        return _getFromBuild(self.packageable, build)
    def getBuiltFiles(self, build):
        return _getFromBuild(self.built_files, build)
    def getDataFiles(self, build):
        return _getFromBuild(self.data_files, build)
    def getPackagingCmd(self, build):
        return _getFromBuild(self.packaging_cmd, build)
    def getStripCmd(self, build):
        return _getFromBuild(self.strip_cmd, build)
    def canBuildTests(self, build):
        return _getFromBuild(self.testable, build)
    def canRunTests(self, build):
        return _getFromBuild(self.run_tests, build)


platforms = []

def debian_x86_64():
    platform = Platform("debian-x86_64")
    platform.env["CXX"] = "ccache g++"
    platform.configureargs.append("--host=x86_64-linux-gnu")
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm" ],
        builds.ScummVMToolsBuild: [
            "construct_mohawk",
            "create_sjisfnt",
            "decine",
            #"decompile", # Decompiler currently not built - BOOST library not present
            "degob",
            "dekyra",
            "descumm",
            "desword2",
            "extract_mohawk",
            "gob_loadcalc",
            #"scummvm-tools", # GUI tools currently not built - WxWidgets library not present
            "scummvm-tools-cli"
        ]
    }
    platform.run_tests = True
    platforms.append(platform)
debian_x86_64()

def ps3():
    platform = Platform("ps3")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache powerpc64-ps3-elf-g++"
    platform.configureargs.append("--host=ps3")
    platform.packaging_cmd = "ps3pkg"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm-ps3.pkg" ],
    }
    platform.testable = False
    platform.run_tests = False
    platforms.append(platform)
ps3()

def psp():
    platform = Platform("psp")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache psp-g++"
    platform.configureargs.extend(["--host=psp", "--disable-debug", "--enable-plugins", "--default-dynamic"])

    # HACK: The glk engine causes linker errors on psp buildbot, and is disabled.
    # This was decided after discussion with dreammaster on irc.
    # Since glk is an interactive fiction engine that requires lots of text entry,
    # and there's no physical keyboard support on this platform, the engine is
    # not comfortably usable on the psp anyways.
    # Unstable engines are disabled because they cause a crash on real hardware when
    # adding a game (see further comment in the pspfull buildbot target)
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-engines=glk", "--disable-all-unstable-engines" ],
        builds.ScummVMStableBuild: [ ],
    }
    platform.built_files = {
        builds.ScummVMBuild: [
            "EBOOT.PBP",
            "plugins",
        ],
    }
    platform.data_files = {
        builds.ScummVMBuild: [
            "backends/platform/psp/kbd",
        ],
    }
    platform.archiveext = "tar.xz"
    platform.testable = False
    platform.run_tests = False
    platforms.append(platform)

    # PSP full
    platform = copy.deepcopy(platform)
    platform.name = "pspfull"

    # This psp build includes all unstable engines, but crashes when adding a game.
    # The crash happens while it loads all the plugins to determine the engine
    # that matches the game. It is a hard crash that requires removing and
    # reinserting the battery. The crash does not happen on the PPSSPP emulator.
    #
    # HACK: The glk engine causes linker errors on psp buildbot, and is disabled.
    # This was decided after discussion with dreammaster on irc.
    # Since glk is an interactive fiction engine that requires lots of text entry,
    # and there's no physical keyboard support on this platform, the engine is
    # not comfortably usable on the psp anyways.
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-engines=glk" ],
        builds.ScummVMStableBuild: [ ],
    }
    platforms.append(platform)
psp()

def raspberrypi():
    platform = Platform("raspberrypi")
    platform.env["CXX"] = "ccache arm-linux-gnueabihf-g++"
    platform.configureargs.append("--host=raspberrypi")
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm" ],
        builds.ScummVMToolsBuild: [
            "construct_mohawk",
            "create_sjisfnt",
            "decine",
            #"decompile", # Decompiler currently not built - BOOST library not present
            "degob",
            "dekyra",
            "descumm",
            "desword2",
            "extract_mohawk",
            "gob_loadcalc",
            #"scummvm-tools", # GUI tools currently not built - WxWidgets library not present
            "scummvm-tools-cli"
        ]
    }
    platforms.append(platform)
raspberrypi()

def vita():
    platform = Platform("vita")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /usr/local/vitasdk/bin/arm-vita-eabi-g++"
    platform.configureargs.append("--host=psp2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-engines=lastexpress", "--disable-engines=glk" ],
        builds.ScummVMStableBuild: [ "--disable-engines=lastexpress" ],
    }
    platform.packaging_cmd = "psp2vpk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.vpk" ],
    }
    platform.archiveext = "zip"
    platform.testable = False
    platform.run_tests = False
    platforms.append(platform)
vita()

def windows_x86_64():
    platform = Platform("windows-x86_64")
    platform.env["CXX"] = "ccache x86_64-w64-mingw32-g++"
    # Add iphlpapi to librairies (should be done in configure script like in create_project)
    platform.env["SDL_NET_LIBS"] = "-lSDL2_net -liphlpapi"
    # Fluidsynth will be linked statically
    platform.env["FLUIDSYNTH_CFLAGS"] = "-DFLUIDSYNTH_NOT_A_DLL"
    platform.configureargs.append("--host=x86_64-w64-mingw32")
    platform.configureargs.append("--enable-updates")
    platform.configureargs.append("--enable-libcurl")
    platform.configureargs.append("--enable-sdlnet")
    platform.built_files = {
        # SDL2 is not really built but we give there an absolute path that must not be appended to src path
        builds.ScummVMBuild: [ "scummvm.exe", "/usr/x86_64-w64-mingw32/bin/SDL2.dll", "/usr/x86_64-w64-mingw32/bin/WinSparkle.dll" ],
        builds.ScummVMToolsBuild: [
            "construct_mohawk.exe",
            "create_sjisfnt.exe",
            "decine.exe",
            #"decompile.exe", # Decompiler currently not built - BOOST library not present
            "degob.exe",
            "dekyra.exe",
            "descumm.exe",
            "desword2.exe",
            "extract_mohawk.exe",
            "gob_loadcalc.exe",
            #"scummvm-tools.exe", # GUI tools currently not built - WxWidgets library not present
            "scummvm-tools-cli.exe"
        ]
    }
    platform.archiveext = "zip"
    platform.run_tests = False
    platforms.append(platform)
windows_x86_64()
