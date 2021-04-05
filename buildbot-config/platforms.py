import copy

from buildbot.plugins import util

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
            'workerimage', 'lock_access',
            'icon', 'description_']

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

        self.workerimage = name
        # A callable taking the build object as argument and
        # which returns a LockAccess to be used when building platform
        self.lock_access = None

        # For snapshots list
        self.icon = None
        self.description_ = None

    @property
    def description(self):
        return self.description_ or self.name

    @description.setter
    def description(self, value):
        self.description_ = value

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
    # Include CA certificates bundle to allow HTTPS
    platform.env["DIST_3DS_EXTRA_FILES"] = "${DEVKITPRO}/cacert.pem"
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

    platform.description = "Nintendo 3DS"
    platform.icon = "3ds"

    register_platform(platform)
_3ds()

def amigaos4():
    platform = Platform("amigaos4")
    platform.env["CXX"] = "ccache /usr/local/amigaos4/bin/ppc-amigaos-c++"
    platform.configureargs.append("--host=ppc-amigaos")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static" ],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "amigaosdist",
        builds.ScummVMToolsBuild: "amigaosdist"
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "Games:ScummVM", "Games:ScummVM.info" ],
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
        ],
    }
    platform.archiveext = "zip"

    platform.description = "Amiga OS4"
    platform.icon = "amiga"

    register_platform(platform)
amigaos4()

# Android environment can't be specified in worker Dockerfile as it's a unified toolchain
# So we must pollute our configuration
def android(suffix, scummvm_target, ndk_target, cxx_target, abi_version,
        description=None):
    platform = Platform("android-{0}".format(suffix))
    platform.compatibleBuilds = (builds.ScummVMBuild, )

    # Use a lock between all Android builds to avoid concurrency conflicts in gradle
    platform.lock_access = (lambda build: android.lock.access('exclusive'))
    platform.workerimage = {
        builds.ScummVMBuild: "android",
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
    }

    platform.configureargs.append("--host=android-{0}".format(scummvm_target))
    platform.configureargs.append("--enable-debug")
    platform.packaging_cmd = "androiddistdebug"
    platform.built_files = {
        builds.ScummVMBuild: [ "debug" ],
    }
    platform.archiveext = "zip"
    platform.testable = False

    platform.description = description
    platform.icon = "android"

    register_platform(platform)
android.lock = util.MasterLock("android")
android(suffix="arm",
        scummvm_target="arm-v7a",
        ndk_target="arm-linux-androideabi",
        cxx_target="armv7a-linux-androideabi",
        abi_version=16,
        description="Android (ARM)")
android(suffix="arm64",
        scummvm_target="arm64-v8a",
        ndk_target="aarch64-linux-android",
        cxx_target="aarch64-linux-android",
        abi_version=21,
        description="Android (ARM 64\xa0bits)")
android(suffix="x86",
        scummvm_target="x86",
        ndk_target="i686-linux-android",
        cxx_target="i686-linux-android",
        abi_version=16,
        description="Android (x86)")
android(suffix="x86-64",
        scummvm_target="x86_64",
        ndk_target="x86_64-linux-android",
        cxx_target="x86_64-linux-android",
        abi_version=21,
        description="Android (x86 64\xa0bits)")

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

    platform.description = "GamePark Caanoo"
    platform.icon = "caanoo"

    register_platform(platform)
caanoo()

def debian(name_suffix, image_suffix, host,
        package=True,
        build_tests=True, run_tests=True,
        buildconfigureargs=None, tools=True,
        description=None):
    platform = Platform("debian-{0}".format(name_suffix))
    platform.workerimage = "debian-{0}".format(image_suffix)
    if not tools:
        platform.compatibleBuilds = (builds.ScummVMBuild, )

    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host={0}".format(host))
    if buildconfigureargs:
        platform.buildconfigureargs = buildconfigureargs

    # stable build don't have this target yet
    platform.packaging_cmd = {
        builds.ScummVMBuild: "dist-generic",
        builds.ScummVMStableBuild: None,
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "dist-generic/*" ],
        # stable build will use produced binary and additional files mentioned in builds.py
        builds.ScummVMStableBuild: [ "scummvm" ],
        builds.ScummVMToolsBuild: [
            "construct_mohawk",
            "create_sjisfnt",
            "decine",
            "decompile",
            "degob",
            "dekyra",
            "descumm",
            "desword2",
            "extract_mohawk",
            "gob_loadcalc",
            "scummvm-tools",
            "scummvm-tools-cli"
        ]
    }
    platform.testable = build_tests
    platform.run_tests = run_tests
    platform.packageable = package

    platform.description = description
    platform.icon = 'debian'

    register_platform(platform)
debian("i686", "x86", "i686-linux-gnu", description="Debian (32\xa0bits)")
debian("x86-64", "x86_64", "x86_64-linux-gnu", description="Debian (64\xa0bits)")
debian("x86-64-nullbackend", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    build_tests=False, run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--backend=null", "--enable-opl2lpt", "--enable-text-console" ],
    })
debian("x86-64-testengine", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    build_tests=False, run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-all-engines", "--enable-engine=testbed",],
    })
debian("x86-64-clang", "x86_64-clang", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False)
debian("x86-64-plugins", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    build_tests=False, run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    })
debian("x86-64-dynamic-detection", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    build_tests=False, run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-detection-dynamic" ],
        # In stable, detection code was in engines
        builds.ScummVMStableBuild: [ "--enable-plugins", "--default-dynamic" ],
    })

def dreamcast():
    platform = Platform("dreamcast")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host=dreamcast")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "dcdist"
    platform.built_files = {
        builds.ScummVMBuild: [ "dcdist/scummvm" ],
    }
    platform.archiveext = "tar.xz"

    platform.description = "Dreamcast"
    platform.icon = 'dc'

    register_platform(platform)

    # Dreamcast with serial debugging
    platform = copy.deepcopy(platform)
    platform.name = "dreamcast-debug"

    platform.buildconfigureargs[builds.ScummVMBuild].append('--enable-debug')

    platform.description = "Dreamcast with serial port debugging"

    register_platform(platform)
dreamcast()

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

    platform.description = "Nintendo Gamecube"
    platform.icon = 'gc'

    register_platform(platform)
gamecube()

def gcw0():
    platform = Platform("gcw0")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host=gcw0")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd" ],
    }
    platform.packaging_cmd = "gcw-opk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.opk" ],
    }
    platform.archiveext = "tar.bz2"

    platform.description = "GCW-Zero"
    platform.icon = 'gcw0'

    register_platform(platform)
gcw0()

def gp2x():
    def setup(p):
        platform.workerimage = "open2x"
        platform.compatibleBuilds = (builds.ScummVMBuild, )
        platform.env["CXX"] = "ccache /opt/open2x/bin/arm-open2x-linux-g++"

        # ScummVM configure adds -march
        # Override CXXFLAGS to avoid warnings about redundant setting between -march and -mcpu
        cxxflags = platform.env.get("CXXFLAGS", '').replace('${CXXFLAGS}', '')
        cxxflags += " -O3 -ffast-math -fomit-frame-pointer"
        platform.buildenv[builds.ScummVMBuild] = {
            'CXXFLAGS': cxxflags,
        }
        platform.configureargs.append("--host=gp2x")
        platform.packaging_cmd = "gp2x-bundle"
        platform.built_files = {
            builds.ScummVMBuild: [ "release/scummvm-gp2x.tar.bz2" ],
        }
        platform.archiveext = "tar.bz2"

        platform.icon = 'gp2x'

    platform = Platform("gp2x-1")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-vkeybd",
            # Disable big engines
            "--disable-engines=bladerunner,glk,kyra,lastexpress,titanic,tsage,ultima" ],
    }
    platform.description = "GamePark GP2X (all except Blade Runner, Glk, Kyra, The Last Express, Starship Titanic, TsAGE, Ultima)"
    setup(platform)
    register_platform(platform)

    platform = Platform("gp2x-2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-vkeybd",
            # Only the other ones
            "--disable-all-engines",
            "--enable-engines=bladerunner,glk,kyra,lastexpress,titanic,tsage,ultima" ],
    }
    platform.description = "GamePark GP2X (Blade Runner, Glk, Kyra, The Last Express, Starship Titanic, TsAGE, Ultima)"
    setup(platform)
    register_platform(platform)
gp2x()

def ios7_arm64():
    platform = Platform("ios7-arm64")
    platform.workerimage = "iphone"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host=ios7-arm64")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static", "--with-staticlib-prefix=${PREFIX}"],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "ios7bundle",
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "ScummVM.app" ],
    }
    platform.archiveext = "tar.bz2"

    platform.description = "iOS 7.1+ (arm64)"
    platform.icon = 'iphone'

    register_platform(platform)
ios7_arm64()

def macosx_arm64():
    platform = Platform("macosx-arm64")
    platform.env["CXX"] = "ccache arm64-apple-darwin20.2-c++"
    # configure script doesn't compile discord check with proper flags
    platform.env["DISCORD_LIBS"] = "-framework AppKit"

    platform.configureargs.append("--host=aarch64-apple-darwin20.2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static",
            "--with-staticlib-prefix=${DESTDIR}/${PREFIX}",
            "--with-sparkle-prefix=${DESTDIR}/${PREFIX}/Library/Frameworks",
            "--disable-osx-dock-plugin", "--enable-updates"],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "bundle",
        builds.ScummVMToolsBuild: None
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "ScummVM.app" ],
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
    platform.archiveext = "tar.xz"

    platform.description = "Mac OS X (M1)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_arm64()

def macosx_x86_64():
    platform = Platform("macosx-x86_64")
    platform.env["CXX"] = "ccache x86_64-apple-darwin20.2-c++"
    # configure script doesn't compile discord check with proper flags
    platform.env["DISCORD_LIBS"] = "-framework AppKit"

    platform.configureargs.append("--host=x86_64-apple-darwin20.2")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static",
            "--with-staticlib-prefix=${DESTDIR}/${PREFIX}",
            "--with-sparkle-prefix=${DESTDIR}/${PREFIX}/Library/Frameworks",
            "--disable-osx-dock-plugin", "--enable-updates"],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "bundle",
        builds.ScummVMToolsBuild: None
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "ScummVM.app" ],
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
    platform.archiveext = "tar.xz"

    platform.description = "Mac OS X (Intel x64)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_x86_64()

def macosx_i386():
    platform = Platform("macosx-i386")
    platform.env["CXX"] = "ccache i386-apple-darwin17-c++"
    platform.configureargs.append("--host=i386-apple-darwin17")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static", "--with-staticlib-prefix=${DESTDIR}/${PREFIX}",
            "--disable-osx-dock-plugin"],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "bundle",
        builds.ScummVMToolsBuild: None
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "ScummVM.app" ],
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
    platform.archiveext = "tar.xz"

    platform.description = "Mac OS X (Intel x86)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_i386()

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
        builds.ScummVMBuild: [ "scummvm.nds" ],
    }
    platform.archiveext = "zip"
    platform.testable = False

    platform.description = "Nintendo DS"
    platform.icon = 'ds'

    register_platform(platform)
nds()

def opendingux():
    platform = Platform("opendingux")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host=dingux")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-vkeybd",
            # Our Tremor decoder is too old for use with Theora, we could have a more recent version
            # but Theora is quite CPU intensive anyway
            "--disable-theoradec" ],
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm", "plugins" ],
    }
    platform.archiveext = "tar.xz"

    platform.description = "OpenDingux"
    platform.icon = 'dingux'

    register_platform(platform)
opendingux()

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

    platform.description = "OpenPandora"
    platform.icon = 'openpandora'

    register_platform(platform)
openpandora()

def ps3():
    platform = Platform("ps3")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    # Include CA certificates bundle to allow HTTPS
    platform.env["DIST_PS3_EXTRA_FILES"] = "${PS3DEV}/cacert.pem"
    platform.env["CXX"] = "ccache powerpc64-ps3-elf-g++"
    platform.configureargs.append("--host=ps3")
    platform.packaging_cmd = "ps3pkg"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm-ps3.pkg" ],
    }

    platform.description = "PlayStation 3"
    platform.icon = 'ps3'

    register_platform(platform)
ps3()

def psp():
    platform = Platform("psp")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache psp-g++"
    platform.configureargs.extend(["--host=psp", "--disable-debug", "--enable-plugins", "--default-dynamic"])

    # HACK: The Ultima engine, when included, causes a crash in the add game dialog
    # after selecting a game in the "Add Game" dialog and clicking on "Choose".
    # This crash happens only on real hardware, but not on the PSP emulator PPSSPP.
    # It was suggested that this is due to memory constraints on the platform.
    # Due to this crash, we disable Ultima on PSP for now.

    # Unstable engines are disabled because they cause a crash on real hardware when
    # adding a game (see further comment in the pspfull buildbot target)

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-engines=ultima", "--disable-all-unstable-engines" ],
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

    platform.description = "PlayStation Portable"
    platform.icon = 'psp'

    register_platform(platform)

    # PSP full
    platform = copy.deepcopy(platform)
    platform.name = "pspfull"
    # Don't package as it doesn't work
    platform.packageable = False

    # This psp build includes all unstable engines, but crashes when adding a game.
    # The crash happens while it loads all the plugins to determine the engine
    # that matches the game. It is a hard crash that requires removing and
    # reinserting the battery. The crash does not happen on the PPSSPP emulator.

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ ],
    }

    platform.description = None

    register_platform(platform)
psp()

def raspberrypi():
    platform = Platform("raspberrypi")
    platform.env["CXX"] = "ccache ${CXX}"
    platform.configureargs.append("--host=raspberrypi")

    # stable build don't have this target yet
    platform.packaging_cmd = {
        builds.ScummVMBuild: "dist-generic",
        builds.ScummVMStableBuild: None,
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "dist-generic/*" ],
        # stable build will use produced binary and additional files mentioned in builds.py
        builds.ScummVMStableBuild: [ "scummvm" ],
        builds.ScummVMToolsBuild: [
            "construct_mohawk",
            "create_sjisfnt",
            "decine",
            "decompile",
            "degob",
            "dekyra",
            "descumm",
            "desword2",
            "extract_mohawk",
            "gob_loadcalc",
            "scummvm-tools",
            "scummvm-tools-cli"
        ]
    }

    platform.description = "Raspberry Pi"
    platform.icon = 'raspberry'

    register_platform(platform)
raspberrypi()

def riscos(suffix, prefix_subdir, variable_suffix, host, description = None):
    if len(prefix_subdir) and prefix_subdir[-1:] != '/':
        prefix_subdir += '/'

    def setup(platform):
        platform.workerimage = 'riscos'

        include_dir = "-isysroot ${{PREFIX}}/{0}include".format(prefix_subdir)
        lib_dir = "-L${{PREFIX}}/{0}lib".format(prefix_subdir)
        env_paths = {
            'CFLAGS': include_dir,
            'CPPFLAGS': include_dir,
            'CXXFLAGS': include_dir,
            'LDFLAGS': lib_dir,
        }

        platform.env["CXX"] = "ccache ${CXX}"
        platform.env["PKG_CONFIG_LIBDIR"] = "${{PREFIX}}/{0}lib/pkgconfig".format(prefix_subdir)
        for v, p in env_paths.items():
            platform.env[v] = ' '.join([
                p, # Path specified above
                platform.env.get(v, "${{{0}}}".format(v)), # User provided flags or worker default ones
                "${{{0}_{1}}}".format(v, variable_suffix) # Variant specific flags (vfp...)
            ])

        platform.configureargs.append("--host={0}".format(host))
        platform.packaging_cmd = "riscosdist"
        platform.built_files = {
            builds.ScummVMBuild: [ "!ScummVM" ],
            builds.ScummVMToolsBuild: [ "!ScummTool" ],
        }
        platform.archiveext = "zip"
        platform.testable = False

        platform.icon = 'riscos'

    platform = Platform("riscos{0}{1}-1".format('-' if suffix else '', suffix))
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            # Disable big engines
            "--disable-engines=ags,bladerunner,glk,kyra,lastexpress,titanic,tsage,ultima" ],
    }
    setup(platform)

    platform.description = description + ' (all except AGS, Blade Runner, Glk, Kyra, The Last Express, Starship Titanic, TsAGE, Ultima)'

    register_platform(platform)

    platform = Platform("riscos{0}{1}-2".format('-' if suffix else '', suffix))
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            # Only the other ones
            "--disable-all-engines",
            "--enable-engines=ags,bladerunner,glk,kyra,lastexpress,titanic,tsage,ultima" ],
    }
    setup(platform)

    platform.description = description + ' (AGS, Blade Runner, Glk, Kyra, The Last Express, Starship Titanic, TsAGE, Ultima)'

    register_platform(platform)
riscos("", "", "STD", "arm-unknown-riscos", "RISC OS")
riscos("vfp", "vfp", "VFP", "arm-vfp-riscos", "RISC OS with VFP")

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

    platform.description = "Nintendo Switch"
    platform.icon = 'switch'

    register_platform(platform)
switch()

def vita():
    platform = Platform("vita")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.env["CXX"] = "ccache /usr/local/vitasdk/bin/arm-vita-eabi-g++"
    platform.configureargs.append("--host=psp2")

    # HACK: To prevent memory-related crash on startup that seems related to the size of the executable
    # file, which grows with number of engines, we need to disable some of the engines...
    # Blade Runner is unplayably slow on the Vita.
    # Stark engine doesn't have a supported renderer on Vita.
    # Myst 3 engine is unplayably slow on Vita.
    # Glk is not very usable on Vita without a keyboard.
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            "--disable-engines=bladerunner",
            "--disable-engines=stark",
            "--disable-engines=myst3",
            "--disable-engines=glk",
        ],
        # Stable doesn't have myst3 nor stark
        builds.ScummVMStableBuild: [
            "--disable-engines=bladerunner",
            "--disable-engines=glk",
        ],
    }
    platform.packaging_cmd = "psp2vpk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.vpk" ],
    }
    platform.archiveext = "zip"
    platform.testable = False

    platform.description = "PlayStation Vita"
    platform.icon = 'psp2'

    register_platform(platform)

    # Vita full
    platform = copy.deepcopy(platform)
    platform.name = "vitafull"
    # Don't package as it doesn't work
    platform.packageable = False

    # This Vita build includes all engines, but crashes on startup.
    # The crash presumably happens due to the large executable size.

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ ],
    }

    platform.description = None

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

    platform.description = "Nintendo Wii"
    platform.icon = 'wii'

    register_platform(platform)
wii()

def windows_mxe(suffix, target, description=None):
    platform = Platform("windows-{0}".format(suffix))
    platform.workerimage = "mxe"

    platform.env["CXX"] = "ccache ${{MXE_PREFIX_DIR}}/bin/{0}-c++".format(target)
    # strip is specified below, just be coherent and define it with environment
    platform.env["STRIP"] = "${{MXE_PREFIX_DIR}}/bin/{0}-strip".format(target)
    # strings is detected using host alias and not host, override it here
    platform.env["STRINGS"] = "${{MXE_PREFIX_DIR}}/bin/{0}-strings".format(target)
    platform.env["PKG_CONFIG_LIBDIR"] = "${{MXE_PREFIX_DIR}}/{0}/lib/pkgconfig".format(target)
    # Altering PATH for curl-config, that lets us reuse environment variables instead of using configure args
    platform.env["PATH"] = [ "${PATH}", "${{MXE_PREFIX_DIR}}/{0}/bin".format(target)]
    # Add iphlpapi to librairies (should be done in configure script like in create_project)
    platform.env["SDL_NET_LIBS"] = "-lSDL2_net -lws2_32 -liphlpapi"

    platform.configureargs.append("--host={0}".format(target))
    platform.configureargs.append("--enable-debug")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-updates"],
    }
    platform.strip_cmd = {
        # As we use an environment variable, we need to use string to spawn a shell
        builds.ScummVMBuild: '"${STRIP}" scummvm.exe',
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.exe" ],
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
    # WinSparkle is built as a DLL (because we don't build it), so add it to the package
    platform.data_files = {
        builds.ScummVMBuild: [
            "${{MXE_PREFIX_DIR}}/{0}/bin/WinSparkle.dll".format(target),
        ],
    }
    platform.archiveext = "zip"

    platform.description = description
    platform.icon = 'windows'

    register_platform(platform)

windows_mxe(suffix="x86",
        target="i686-w64-mingw32.static",
        description="Windows (32\xa0bits)")
windows_mxe(suffix="x86-64",
        target="x86_64-w64-mingw32.static",
        description="Windows (64\xa0bits)")
