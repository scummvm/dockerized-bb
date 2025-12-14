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
        return False
    if build.name in data:
        return True
    for cls in type(build).mro():
        if cls in data:
            return True
    return False

class Platform:
    __slots__ = ['name',
            'compatibleBuilds', 'incompatibleBuilds',
            'env', 'buildenv',
            'configureargs', 'buildconfigureargs',
            'packageable', 'built_files', 'data_files',
            'packaging_cmd', 'strip_cmd', 'archiveext',
            'run_tests', 'build_devtools',
            'workerimage', 'lock_access',
            'icon', 'description_']

    def __init__(self, name):
        self.name = name
        self.compatibleBuilds = None
        # To blacklist stable ScummVM for example
        self.incompatibleBuilds = []
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
        # Can run tests
        self.run_tests = False

        self.build_devtools = False

        self.workerimage = name
        # A callable taking the build object as argument and
        # which returns a LockAccess to be used when building platform
        self.lock_access = None

        # For daily builds list
        self.icon = None
        self.description_ = None

    @property
    def description(self):
        return self.description_ or self.name

    @description.setter
    def description(self, value):
        self.description_ = value

    def canBuild(self, build):
        return (_buildInData(self.compatibleBuilds, build) and
                not _buildInData(self.incompatibleBuilds, build))
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
    platform.configureargs.append("--host=3ds")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    }
    platform.packaging_cmd = "dist_3ds"
    platform.built_files = {
        builds.ScummVMBuild: [ "dist_3ds/*" ],
    }
    platform.archiveext = "zip"

    platform.description = "Nintendo 3DS"
    platform.icon = "3ds"

    register_platform(platform)
_3ds()

def amigaos4():
    platform = Platform("amigaos4")
    platform.configureargs.append("--host=ppc-amigaos")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-detection-dynamic" ],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "amigaosdist",
        builds.ScummVMToolsBuild: "amigaosdist"
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "install", "install.info" ],
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
            "CXX": "${{ANDROID_TOOLCHAIN}}/bin/{0}{1}-clang++".format(
                cxx_target, abi_version),
            # Worker has all libraries installed in the NDK sysroot
            "PKG_CONFIG_LIBDIR": "${{ANDROID_TOOLCHAIN}}/sysroot/usr/lib/{0}/{1}/pkgconfig".format(
                ndk_target, abi_version),
            # Altering PATH for curl-config, that lets us reuse environment variables instead of using configure args
            "PATH": [ "${PATH}", "${{ANDROID_TOOLCHAIN}}/sysroot/usr/bin/{0}/{1}".format(
                ndk_target, abi_version)],
        },
    }
    # Include CA certificates bundle to allow HTTPS
    platform.env["DIST_ANDROID_CACERT_PEM"] = "${RO_ANDROID_ROOT}/cacert.pem"

    platform.configureargs.append("--host=android-{0}".format(scummvm_target))
    platform.configureargs.append("--enable-debug")
    platform.packaging_cmd = "androiddistdebug"
    platform.built_files = {
        builds.ScummVMBuild: [ "debug" ],
    }
    platform.archiveext = "zip"

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

def appletv():
    platform = Platform("appletv")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=tvos")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static", "--with-staticlib-prefix=${PREFIX}"],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: "tvosbundle",
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "ScummVM.app" ],
    }
    platform.archiveext = "tar.bz2"

    platform.description = "Apple TV"
    platform.icon = 'appletv'

    register_platform(platform)
appletv()

def atari():
    platform = Platform("atari")
    platform.compatibleBuilds = (builds.ScummVMBuild, )

    platform.env["ASFLAGS"] = "-m68020-60"
    platform.env["CXXFLAGS"] = "-m68020-60 -DUSE_MOVE16 -DUSE_SUPERVIDEL -DUSE_SV_BLITTER -DDISABLE_LAUNCHERDISPLAY_GRID"
    platform.env["LDFLAGS"] = "-m68020-60"
    platform.env["PKG_CONFIG_LIBDIR"] = "${PREFIX}/lib/m68020-60/pkgconfig"

    # TODO: custom patches, icons

    platform.configureargs.append("--host=m68k-atari-mintelf")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--backend=atari" ],
    }

    platform.packaging_cmd = {
        builds.ScummVMBuild: "atarifulldist",
    }

    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm-*-atari-full/*" ],
    }
    platform.archiveext = "zip"

    platform.description = "Atari Full"
    #platform.icon = 'atari-full'
    register_platform(platform)

    # Atari Lite
    platform = copy.deepcopy(platform)
    platform.name = "atari-lite"

    platform.env["ASFLAGS"] = "-m68030"
    platform.env["CXXFLAGS"] = "-m68030 -DDISABLE_FANCY_THEMES"
    platform.env["LDFLAGS"] = "-m68030"

    platform.buildconfigureargs[builds.ScummVMBuild].append('--disable-highres')
    platform.buildconfigureargs[builds.ScummVMBuild].append('--disable-bink')

    platform.packaging_cmd = {
        builds.ScummVMBuild: "atarilitedist",
    }

    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm-*-atari-lite/*" ],
    }

    platform.description = "Atari Lite"
    #platform.icon = 'atari-lite'
    register_platform(platform)

    # FireBee
    platform = copy.deepcopy(platform)
    platform.name = "firebee"

    del platform.env["ASFLAGS"]
    platform.env["CXXFLAGS"] = "-mcpu=5475"
    platform.env["LDFLAGS"] = "-mcpu=5475"
    platform.env["PKG_CONFIG_LIBDIR"] = "${PREFIX}/lib/m5475/pkgconfig"

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            "--backend=sdl",
            # Workaround: ${PREFIX} doesn't seem to be expanded
            "--with-sdl-prefix=/opt/toolchains/atari/m68k-atari-mintelf/sys-root/usr/bin/m5475",
            "--with-freetype2-prefix=/opt/toolchains/atari/m68k-atari-mintelf/sys-root/usr/bin/m5475",
            "--with-mikmod-prefix=/opt/toolchains/atari/m68k-atari-mintelf/sys-root/usr/bin/m5475" ]
            # "--with-sdl-prefix=${PREFIX}/bin/m5475",
            # "--with-freetype2-prefix=${PREFIX}/bin/m5475",
            # "--with-mikmod-prefix=${PREFIX}/bin/m5475" ]
    }

    platform.packaging_cmd = {
        builds.ScummVMBuild: "fbdist",
    }

    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm-*-firebee/*" ],
    }

    platform.description = "FireBee"
    #platform.icon = 'firebee'
    register_platform(platform)
#atari()

def debian(name_suffix, image_suffix, host,
        package=True,
        run_tests=True, build_devtools=False,
        buildconfigureargs=None, env=None, tools=True,
        description=None):
    platform = Platform("debian-{0}".format(name_suffix))
    platform.workerimage = "debian-{0}".format(image_suffix)
    if not tools:
        platform.compatibleBuilds = (builds.ScummVMBuild, )

    if env:
        platform.env.update(env)

    platform.configureargs.append("--host={0}".format(host))
    if buildconfigureargs:
        platform.buildconfigureargs = buildconfigureargs

    platform.packaging_cmd = {
        builds.ScummVMBuild: "dist-generic",
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "dist-generic/*" ],
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
    platform.run_tests = run_tests
    platform.build_devtools = build_devtools
    platform.packageable = package

    platform.description = description
    platform.icon = 'debian'

    register_platform(platform)
debian("i686", "x86", "i686-linux-gnu", description="Debian (32\xa0bits)")
debian("x86-64", "x86_64", "x86_64-linux-gnu", description="Debian (64\xa0bits)",
    build_devtools=True)
debian("x86-64-nullbackend", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--backend=null", "--enable-opl2lpt", "--enable-text-console" ],
    })
debian("x86-64-clang", "x86_64-clang", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False, build_devtools=True)
debian("x86-64-plugins", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    })
debian("x86-64-dynamic-detection", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-detection-dynamic" ],
    })
debian("x86-64-sdl1.2", "x86_64", "x86_64-linux-gnu", package=False, tools=False,
    run_tests=False,
    buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-all-engines", "--enable-engine=testbed",],
    },
    env = {
        'SDL_CONFIG':'sdl-config',
    })

def dreamcast():
    platform = Platform("dreamcast")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
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
    platform.configureargs.append("--host=gamecube")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-detection-dynamic", "--enable-vkeybd" ],
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

def ios7_arm64():
    platform = Platform("ios7-arm64")
    platform.workerimage = "iphone"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
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
    # configure script doesn't compile discord check with proper flags
    platform.env["DISCORD_LIBS"] = "-framework AppKit"

    platform.configureargs.append("--host=aarch64-apple-darwin25.1")
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

    platform.description = "Mac OS (Apple Silicon)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_arm64()

def macosx_x86_64():
    platform = Platform("macosx-x86_64")
    # configure script doesn't compile discord check with proper flags
    platform.env["DISCORD_LIBS"] = "-framework AppKit"

    platform.configureargs.append("--host=x86_64-apple-darwin25.1")
    # Don't enable updates on x86_64 as the platform is getting older
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-static",
            "--with-staticlib-prefix=${DESTDIR}/${PREFIX}",
            "--with-sparkle-prefix=${DESTDIR}/${PREFIX}/Library/Frameworks",
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

    platform.description = "Mac OS (Intel x64)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_x86_64()

def macosx_i386():
    platform = Platform("macosx-i386")
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
    platform.archiveext = "tar.bz2"

    platform.description = "Mac OS (Intel x86)"
    platform.icon = 'macos'

    register_platform(platform)
macosx_i386()

def miyoo():
    platform = Platform("miyoo")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=miyoo")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--disable-detection-full", "--enable-plugins", "--default-dynamic" ],
    }
    platform.packaging_cmd = "sd-root"
    platform.built_files = {
        builds.ScummVMBuild: [ "sd-root/games", "sd-root/gmenu2x" ],
    }
    platform.archiveext = "tar.xz"

    platform.description = "Miyoo"
    platform.icon = 'miyoo'

    register_platform(platform)
miyoo()

def nds():
    platform = Platform("nds")
    platform.workerimage = "devkitnds"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=ds")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    }
    # stable build don't have this target yet
    platform.packaging_cmd = {
        builds.ScummVMBuild: "dsdist",
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "dsdist/*" ],
    }
    platform.archiveext = "zip"

    platform.description = "Nintendo DS"
    platform.icon = 'ds'

    register_platform(platform)
nds()

# OpenDingux environment can't be specified in worker Dockerfile as it's multiple toolchains
# So we must pollute tell it here
def opendingux_beta(target, toolchain, libc, description=None):
    platform = Platform("opendingux-beta-{0}".format(target))
    platform.compatibleBuilds = (builds.ScummVMBuild, )

    platform.workerimage = "opendingux-beta"
    platform.buildenv = {
        builds.ScummVMBuild: {
            "CXX": "${{OPENDINGUX_ROOT}}/{0}-toolchain/bin/mipsel-linux-c++".format(
                toolchain),
            "PKG_CONFIG_LIBDIR": "${{OPENDINGUX_ROOT}}/{0}-toolchain/mipsel-{0}-linux-{1}/sysroot/usr/lib/pkgconfig".format(
                toolchain, libc),
            "PKG_CONFIG_SYSROOT_DIR": "${{OPENDINGUX_ROOT}}/{0}-toolchain/mipsel-{0}-linux-{1}/sysroot".format(
                toolchain, libc),
            # Alter PATH for all binaries and sdl2-config, that lets us avoid to define all tools we use
            "PATH": [ "${PATH}",
                "${{OPENDINGUX_ROOT}}/{0}-toolchain/mipsel-{0}-linux-{1}/sysroot/usr/bin".format(
                    toolchain, libc),
                "${{OPENDINGUX_ROOT}}/{0}-toolchain/bin".format(
                    toolchain),
            ],
        },
    }

    platform.configureargs.append("--host=opendingux-{0}".format(target))
    platform.packaging_cmd = "od-make-opk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm_{0}.opk".format(target) ],
    }
    platform.archiveext = "zip"

    platform.description = "OpenDingux beta - {0}".format(description)
    platform.icon = "dingux"

    register_platform(platform)
opendingux_beta(target="gcw0",
        toolchain="gcw0",
        libc="uclibc",
        description="GCW0")
opendingux_beta(target="lepus",
        toolchain="lepus",
        libc="musl",
        description="Lepus based boards")
opendingux_beta(target="rs90",
        toolchain="rs90",
        libc="musl",
        description="RS90 & RG99 handhelds")

def ps3():
    platform = Platform("ps3")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    # Include CA certificates bundle to allow HTTPS
    platform.env["DIST_PS3_EXTRA_FILES"] = "${PS3DEV}/cacert.pem"
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
    platform.configureargs.extend(["--host=psp", "--disable-debug", "--enable-plugins", "--default-dynamic"])

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            "--enable-engine=testbed",
        ],
    }
    platform.built_files = {
        builds.ScummVMBuild: [
            "EBOOT.PBP",
            "plugins",
        ],
    }
    platform.data_files = {
        builds.ScummVMBuild: [
            "backends/platform/psp/kbd.zip",
        ],
    }
    platform.archiveext = "tar.xz"

    platform.description = "PlayStation Portable"
    platform.icon = 'psp'

    register_platform(platform)
psp()

def raspberrypi():
    platform = Platform("raspberrypi")
    platform.configureargs.append("--host=raspberrypi")

    platform.packaging_cmd = {
        builds.ScummVMBuild: "dist-generic",
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "dist-generic/*" ],
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

    platform.description = "Raspberry Pi OS (Bookworm)"
    platform.icon = 'raspberry'

    register_platform(platform)
raspberrypi()

def riscos(suffix, prefix_subdir, variable_suffix, host, description = None):
    if len(prefix_subdir) and prefix_subdir[-1:] != '/':
        prefix_subdir += '/'

    platform = Platform("riscos{0}{1}".format('-' if suffix else '', suffix))
    platform.workerimage = 'riscos'

    include_dir = "-isysroot ${{PREFIX}}/{0}include".format(prefix_subdir)
    lib_dir = "-L${{PREFIX}}/{0}lib".format(prefix_subdir)
    env_paths = {
        'CFLAGS': include_dir,
        'CPPFLAGS': include_dir,
        'CXXFLAGS': include_dir,
        'LDFLAGS': lib_dir,
    }

    platform.env["PKG_CONFIG_LIBDIR"] = "${{PREFIX}}/{0}lib/pkgconfig".format(prefix_subdir)
    for v, p in env_paths.items():
        platform.env[v] = ' '.join([
            p, # Path specified above
            platform.env.get(v, "${{{0}}}".format(v)), # User provided flags or worker default ones
            "${{{0}_{1}}}".format(v, variable_suffix) # Variant specific flags (vfp...)
        ])

    platform.configureargs.append("--host={0}".format(host))
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic" ],
    }
    platform.packaging_cmd = "riscosdist"
    platform.built_files = {
        builds.ScummVMBuild: [ "!ScummVM" ],
        builds.ScummVMToolsBuild: [ "!ScummTool" ],
    }
    platform.archiveext = "zip"

    platform.icon = 'riscos'
    platform.description = description

    register_platform(platform)

riscos("", "", "STD", "arm-unknown-riscos", "RISC OS")
riscos("vfp", "vfp", "VFP", "arm-vfp-riscos", "RISC OS with VFP")

def switch():
    platform = Platform("switch")
    platform.workerimage = "devkitswitch"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=switch")
    platform.packaging_cmd = "switch_release"
    platform.built_files = {
        builds.ScummVMBuild: [ "switch_release/*" ],
    }
    platform.archiveext = "zip"

    platform.description = "Nintendo Switch"
    platform.icon = 'switch'

    register_platform(platform)
switch()

def vita():
    platform = Platform("vita")
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=psp2")

    platform.buildconfigureargs = {
        builds.ScummVMBuild: [
            "--enable-plugins"
        ],
    }
    platform.packaging_cmd = "psp2vpk"
    platform.built_files = {
        builds.ScummVMBuild: [ "scummvm.vpk" ],
    }
    platform.archiveext = "zip"

    platform.description = "PlayStation Vita"
    platform.icon = 'psp2'

    register_platform(platform)
vita()

def wii():
    platform = Platform("wii")
    platform.workerimage = "devkitppc"
    platform.compatibleBuilds = (builds.ScummVMBuild, )
    platform.configureargs.append("--host=wii")
    platform.buildconfigureargs = {
        builds.ScummVMBuild: [ "--enable-plugins", "--default-dynamic", "--enable-detection-dynamic", "--enable-vkeybd" ],
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

    platform.env["CXX"] = "${{MXE_PREFIX_DIR}}/bin/{0}-c++".format(target)
    # strip is specified below, just be coherent and define it with environment
    platform.env["STRIP"] = "${{MXE_PREFIX_DIR}}/bin/{0}-strip".format(target)
    # strings is detected using host alias and not host, override it here
    platform.env["STRINGS"] = "${{MXE_PREFIX_DIR}}/bin/{0}-strings".format(target)
    platform.env["PKG_CONFIG_LIBDIR"] = "${{MXE_PREFIX_DIR}}/{0}/lib/pkgconfig".format(target)
    # Altering PATH for curl-config, that lets us reuse environment variables instead of using configure args
    platform.env["PATH"] = [ "${PATH}", "${{MXE_PREFIX_DIR}}/{0}/bin".format(target)]

    platform.configureargs.append("--host={0}".format(target))
    if suffix != 'x86':
        platform.buildconfigureargs = {
            builds.ScummVMBuild: [ "--enable-updates"],
        }
    platform.strip_cmd = {
        # As we use an environment variable, we need to use string to spawn a shell
        builds.ScummVMBuild: '"${STRIP}" scummvm.exe',
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: ["win32dist-mingw", "DESTDIR=win32dist-mingw"],
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "win32dist-mingw" ],
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

    platform.description = description
    platform.icon = 'windows'

    register_platform(platform)

windows_mxe(suffix="x86",
        target="i686-w64-mingw32.static",
        description="Windows (32\xa0bits)")
windows_mxe(suffix="x86-64",
        target="x86_64-w64-mingw32.static",
        description="Windows (64\xa0bits)")

def win9x():
    platform = Platform("win9x")
    platform.workerimage = "windows-9x"

    platform.configureargs.append("--host=mingw32")
    platform.buildconfigureargs = {
        # Disable ENet to not depend on ws2_32.dll which isn't here on vanilla Win95
        builds.ScummVMBuild: [ "--disable-windows-unicode", "--disable-enet" ],
    }
    platform.packaging_cmd = {
        builds.ScummVMBuild: ["win32dist-mingw", "DESTDIR=win32dist-mingw"],
    }
    platform.built_files = {
        builds.ScummVMBuild: [ "win32dist-mingw" ],
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

    platform.description = "Windows 9x"
    platform.icon = 'win95'

    register_platform(platform)
win9x()
