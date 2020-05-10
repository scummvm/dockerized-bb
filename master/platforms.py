import copy
import os

import config
import builds
import workers

def _getFromBuild(data, build):
    if not isinstance(data, dict):
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
    def getWorkerImage(self, build):
        return _getFromBuild(self.workerimage, build)


platforms = []
def register_platform(platform):
    if (config.platforms_whitelist and
            platform.name not in config.platforms_whitelist):
        return
    if (config.platforms_blacklist and
            platform.name in config.platforms_blacklist):
        return
    platforms.append(platform)

def _3ds():
    platform = Platform("3ds")
    platform.workerimage = "devkit3ds"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/devkitpro/devkitARM/bin/arm-none-eabi-c++"
    platform.configureargs.append("--host=3ds")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    }
    platform.packaging_cmd = "dist_3ds"
    platform.built_files = {
        builds.ScummVMBuild: [ "dist_3ds/*" ],
    }
    platform.archiveext = "zip"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
_3ds()

def android(suffix, scummvm_target, ndk_target, cxx_target, abi_version):
    platform = Platform("android_{0}".format(suffix))
    platform.compatibleBuilds = (builds.ScummVMBuild, )

    platform.workerimage = {
        builds.ScummVMBuild: "android",
        builds.ScummVMStableBuild: "android-old",
    }
    platform.buildenv = {
        builds.ScummVMBuild: {
            "CXX": "ccache ${{ANDROID_TOOLCHAIN}}/bin/{0}{1}-clang++".format(
                cxx_target, abi_version),
            # Worker has all libraries installed in the NDK sysroot
            "PKG_CONFIG_LIBDIR": "${{ANDROID_TOOLCHAIN}}/sysroot/usr/lib/{0}/{1}/pkgconfig".format(
                ndk_target, abi_version),
            # Altering PATH for curl-config, that lets us reuse environment variables instead of using configure args
            "PATH": [ "${PATH}", "${{ANDROID_TOOLCHAIN}}/sysroot/usr/bin/{0}/{1}".format(
                ndk_target, abi_version)],
        },
        builds.ScummVMStableBuild: {
            "AR": "${{ANDROID_TOOLCHAIN}}/bin/{0}-ar".format(
                ndk_target),
            "AS": "${{ANDROID_TOOLCHAIN}}/bin/{0}-as".format(
                ndk_target),
            "RANLIB": "${{ANDROID_TOOLCHAIN}}/bin/{0}-ranlib".format(
                ndk_target),
            "STRIP": "${{ANDROID_TOOLCHAIN}}/bin/{0}-strip".format(
                ndk_target),
            "STRINGS": "${{ANDROID_TOOLCHAIN}}/bin/{0}-strings".format(
                ndk_target),
            "CXX": "ccache ${{ANDROID_TOOLCHAIN}}/bin/{0}-clang++".format(
                ndk_target),
            "CC": "ccache ${{ANDROID_TOOLCHAIN}}/bin/{0}-clang".format(
                ndk_target),
            # Worker has all libraries installed in the toolchain
            "PKG_CONFIG_LIBDIR": "${{ANDROID_TOOLCHAIN}}/sysroot/usr/lib/{0}/pkgconfig".format(
                ndk_target),
            # Altering PATH for curl-config, that lets us reuse environment variables instead of using configure args
            "PATH": [ "${PATH}", "${{ANDROID_TOOLCHAIN}}/sysroot/usr/bin/{0}".format(
                ndk_target)],
        }
    }

    platform.configureargs.append("--host=android-{0}".format(scummvm_target))
    platform.configureargs.append("--enable-debug")
    platform.packaging_cmd = "androiddistdebug"
    platform.built_files = {
        builds.ScummVMBuild: [ "debug" ],
    }
    platform.archiveext = "zip"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)

android(suffix="arm",
        scummvm_target="arm-v7a",
        ndk_target="arm-linux-androideabi",
        cxx_target="armv7a-linux-androideabi",
        abi_version=16)
android(suffix="arm64",
        scummvm_target="arm64-v8a",
        ndk_target="aarch64-linux-android",
        cxx_target="aarch64-linux-android",
        abi_version=21)
android(suffix="x86",
        scummvm_target="x86",
        ndk_target="i686-linux-android",
        cxx_target="i686-linux-android",
        abi_version=16)
android(suffix="x86_64",
        scummvm_target="x86_64",
        ndk_target="x86_64-linux-android",
        cxx_target="x86_64-linux-android",
        abi_version=21)

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
    register_platform(platform)
debian_x86_64()

def caanoo():
    platform = Platform("caanoo")
    platform.workerimage = "caanoo"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/caanoo/bin/arm-gph-linux-gnueabi-c++"
    platform.configureargs.append("--host=caanoo")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "caanoo-bundle"
    platform.built_files = {
        builds.ScummVMBuild: [ "release/scummvm-caanoo.tar.bz2" ],
    }
    platform.archiveext = "tar.bz2"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
caanoo()

def gamecube():
    platform = Platform("gamecube")
    platform.workerimage = "devkitppc"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/devkitpro/devkitPPC/bin/powerpc-eabi-c++"
    platform.configureargs.append("--host=gamecube")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "wiidist"
    platform.built_files = {
        builds.ScummVMBuild: [ "wiidist/scummvm" ],
    }
    platform.archiveext = "tar.xz"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
gamecube()

def gp2x():
    def setup(p):
        platform.workerimage = "open2x"
        platform.compatibleBuilds = (builds.ScummVMBuild, )
        platform.env["CXX"] = "ccache /opt/open2x/bin/arm-open2x-linux-g++"
        # Override CXXFLAGS to avoid warnings about redundant setting between -march and -mcpu
        platform.env["CXXFLAGS"] = "-O3 -ffast-math -fomit-frame-pointer"
        platform.configureargs.append("--host=gp2x")
        platform.packaging_cmd = "gp2x-bundle"
        platform.built_files = {
            builds.ScummVMBuild: [ "release/scummvm-gp2x.tar.bz2" ],
        }
        platform.archiveext = "tar.bz2"
        platform.testable = False
        platform.run_tests = False

    platform = Platform("gp2x-1")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-vkeybd",
            # Disable big engines
            "--disable-engines=glk,lastexpress,titanic,tsage,ultima" ],
    }
    setup(platform)
    register_platform(platform)

    platform = Platform("gp2x-2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-vkeybd",
            # Only the other ones
            "--disable-all-engines",
            "--enable-engines=glk,lastexpress,titanic,tsage,ultima" ],
    }
    setup(platform)
    register_platform(platform)
gp2x()

def nds():
    platform = Platform("nds")
    platform.workerimage = "devkitnds"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/devkitpro/devkitARM/bin/arm-none-eabi-c++"
    platform.configureargs.append("--host=ds")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.nds", "plugins" ],
    }
    platform.archiveext = "tar.xz"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
nds()

def openpandora():
    platform = Platform("openpandora")
    platform.workerimage = "openpandora"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/openpandora/bin/arm-angstrom-linux-gnueabi-c++"
    platform.configureargs.append("--host=openpandora")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "op-pnd"
    platform.built_files = {
        builds.ScummVMBuild: [ "release/scummvm-op-pnd.tar.bz2" ],
    }
    platform.archiveext = "tar.bz2"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
openpandora()

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
    register_platform(platform)
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
    register_platform(platform)

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
    register_platform(platform)
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
    register_platform(platform)
raspberrypi()

def switch():
    platform = Platform("switch")
    platform.workerimage = "devkitswitch"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/devkitpro/devkitA64/bin/aarch64-none-elf-c++"
    platform.configureargs.append("--host=switch")
    platform.packaging_cmd = "switch_release"
    platform.built_files = {
        builds.ScummVMBuild: [ "switch_release/*" ],
    }
    platform.archiveext = "zip"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
switch()

def vita():
    platform = Platform("vita")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /usr/local/vitasdk/bin/arm-vita-eabi-g++"
    platform.configureargs.append("--host=psp2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            "--disable-engines=lastexpress",
            "--disable-engines=glk",
            "--disable-engines=dm",
            "--disable-engines=director",
        ],
    }
    platform.packaging_cmd = "psp2vpk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.vpk" ],
    }
    platform.archiveext = "zip"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
vita()

def wii():
    platform = Platform("wii")
    platform.workerimage = "devkitppc"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /opt/devkitpro/devkitPPC/bin/powerpc-eabi-c++"
    platform.configureargs.append("--host=wii")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "wiidist"
    platform.built_files = {
        builds.ScummVMBuild: [ "wiidist/scummvm" ],
    }
    platform.archiveext = "tar.xz"
    platform.testable = False
    platform.run_tests = False
    register_platform(platform)
wii()

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
    register_platform(platform)
windows_x86_64()
