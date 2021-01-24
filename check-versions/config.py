__all__ = ["PATHS", "FILE_PATTERNS", "VERSIONS_REGEXPS", "VERSIONS"]

# This is the root of all paths in this configuration file
# It's relative to check-versions path
ROOT = ".."

# Paths to consider when looking for versions tags
# Can be file or directories
# Relative to ROOT
PATHS = [ "./toolchains", "./workers", "./Makefile" ]

# Only path matching one of this glob pattern will be considered
FILE_PATTERNS = [ "*.sh", "*.m4", "*.mk" ]

# All regular expressions to match: they must have 2 named groups: 'package' and 'version'
VERSIONS_REGEXPS = [
    # Shell style
    r"^\s*(?:export )?(?P<package>[A-Za-z0-9_]+)_VERSION=(?P<version>[A-Za-z0-9._-]+)\s*\\?$",
    # GNU m4 style
    r"m4_define\(`(?P<package>[A-Za-z0-9_]+)_VERSION',\s*(?P<version>[A-Za-z0-9._-]+)\)",
    # GNU Make style
    r"\s*(?P<package>[A-Za-z0-9_]+)_VERSION\s*[:?]?=\s*(?P<version>[A-Za-z0-9._-]+)\s*$",
    # MXE packages
    r"\s*(?P<package>)\$\(PKG\)_VERSION\s*[:?]?=\s*(?P<version>[A-Za-z0-9._-]+)\s*$",
]

# Some checks are used at multiple places
# All of these variables aren't used directly by check-versions

# Apple stuff is used for apple-sdks, macosx and iphone
cctools_port_check = {
    'check': 'git commit',
    'repository': 'https://github.com/tpoechtrager/cctools-port.git',
    'branch': 'master',
}
ldid_check = {
    'check': 'git commit',
    'repository': 'https://github.com/tpoechtrager/ldid.git',
    'branch': 'master',
}
osxcross_check = {
    'check': 'git commit',
    'repository': 'https://github.com/tpoechtrager/osxcross.git',
    'branch': 'master',
}
pbzx_check = {
    'check': 'git commit',
    'repository': 'https://github.com/tpoechtrager/pbzx.git',
    'branch': 'master',
}
xar_check = {
    'check': 'git commit',
    'repository': 'https://github.com/tpoechtrager/xar.git',
    'branch': 'master',
}

discord_rpc_check = {
        'check': 'git tag',
        'repository': 'https://github.com/discord/discord-rpc.git',
        'prefix': 'v',
}
libiconv_check = {
        'check': 'git tag',
        'repository': 'https://git.savannah.gnu.org/git/libiconv.git',
        'prefix': 'v',
}

# The checks parameter for each version tag
# Every entry in the dictionary is keyed by a tuple made of path (relative to ROOT) and package name
# Every value is a dictionnary with a 'check' entry specifying the check to use and its parameters
VERSIONS = {
    ('./Makefile', 'BUILDBOT'): {
        'check': 'git tag',
        'repository': 'https://github.com/buildbot/buildbot.git',
        'prefix': 'v',
        'exclude pattern': r'.*(b|rc)\d+'
    },
    ('./Makefile', 'BOTTLE'): {
        'check': 'git tag',
        'repository': 'https://github.com/bottlepy/bottle.git',
        'exclude pattern': r'.*(b|rc).*'
    },

    ('./toolchains/amigaos4/packages/libsdl2/build.sh', 'SDL2'): {
        'check': 'git tag',
        'repository': 'https://github.com/AmigaPorts/SDL.git',
        # Remove v and -amigaos4
        'prefix': 'v',
        'suffix': '-amigaos4',
        'exclude pattern': r'.*-rc\d+-.*'
    },
    ('./toolchains/amigaos4/packages/regina-rexx/build.sh', 'REXX'): {
        'check': 'svn tag',
        'repository': 'https://svn.code.sf.net/p/regina-rexx/code/interpreter/tags/',
    },
    ('./toolchains/amigaos4/packages/toolchain/build.sh', 'TOOLCHAIN'): {
        'check': 'git commit',
        'repository': 'https://github.com/sba1/adtools.git',
        'branch': 'master',
    },

    ('./toolchains/android-common/functions-sdk.sh', 'CMDLINE_TOOLS'): {
        'check': 'scrape',
        'url': 'https://developer.android.com/studio',
        'filter pattern': r'>commandlinetools-linux-(?P<version>\d+)_latest.zip</'
    },

    # Android NDK must match ScummVM build system
    ('./toolchains/android/Dockerfile.m4', 'ANDROID_NDK'): 'ignore',

    # Recent Xcode don't support i386 anymore
    ('./toolchains/apple-sdks/Dockerfile.m4', 'I386_XCODE'): 'ignore',
    ('./toolchains/apple-sdks/Dockerfile.m4', 'XCODE'): {
        'check': 'apple store',
        'productid': 497799835,
    },
    ('./toolchains/apple-sdks/packages/xcode-extractor/build.sh', 'OSXCROSS'): osxcross_check,
    ('./toolchains/apple-sdks/packages/xcode-extractor/build.sh', 'PBZX'): pbzx_check,
    ('./toolchains/apple-sdks/packages/xcode-extractor/build.sh', 'XAR'): xar_check,

    # Apple SDK and target versions depend on which Xcode is used
    # We already check for it
    ('./toolchains/iphone/Dockerfile.m4', 'IPHONE_SDK'): 'ignore',
    ('./toolchains/macosx-i386/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./toolchains/macosx-i386/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./toolchains/macosx/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./toolchains/macosx/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./workers/iphone/Dockerfile.m4', 'IPHONE_SDK'): 'ignore',
    ('./workers/macosx-i386/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./workers/macosx-i386/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./workers/macosx/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./workers/macosx/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',

    # Caanoo packages (except toolchain) are set by old firmware
    ('./toolchains/caanoo/packages/freetype/build.sh', 'FREETYPE'): 'ignore',
    ('./toolchains/caanoo/packages/libjpeg/build.sh', 'JPEG'): 'ignore',
    ('./toolchains/caanoo/packages/libogg/build.sh', 'LIBOGG'): 'ignore',
    ('./toolchains/caanoo/packages/libpng/build.sh', 'LIBPNG'): 'ignore',
    ('./toolchains/caanoo/packages/libsdl/build.sh', 'SDL'): 'ignore',
    ('./toolchains/caanoo/packages/libvorbisidec/build.sh', 'LIBTREMOR'): 'ignore',
    ('./toolchains/caanoo/packages/sdl-net1.2/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/caanoo/packages/toolchain/build.sh', 'CT_NG'): 'ignore',
    ('./toolchains/caanoo/packages/tslib/build.sh', 'TSLIB'): 'ignore',
    ('./toolchains/caanoo/packages/zlib/build.sh', 'ZLIB'): 'ignore',

    ('./toolchains/common/packages/discord-rpc/build.sh', 'DISCORD_RPC'): discord_rpc_check,
    ('./toolchains/common/packages/fluidsynth-lite/build.sh', 'FLUIDSYNTH'): {
        'check': 'git commit',
        'repository': 'https://github.com/Doom64/fluidsynth-lite.git',
        'branch': 'master',
    },
    ('./toolchains/common/packages/fluidsynth/build.sh', 'FLUIDSYNTH'): {
        'check': 'git tag',
        'repository': 'https://github.com/FluidSynth/fluidsynth.git',
        'prefix': 'v',
        'exclude pattern': r'.*\.(beta|rc)\d+$'
    },
    ('./toolchains/common/packages/libiconv/build.sh', 'LIBICONV'): libiconv_check,

    ('./toolchains/devkit3ds/packages/Project_CTR/build.sh', 'PROJECT_CTR'): {
        'check': 'git tag',
        'repository': 'https://github.com/3DSGuy/Project_CTR.git',
        # Use pattern as prefix would remove it
        'pattern': '^makerom-v',
    },
    ('./toolchains/devkit3ds/packages/bannertool/build.sh', 'BANNERTOOL'): {
        'check': 'git commit',
        'repository': 'https://github.com/Steveice10/bannertool.git',
        'branch': 'master',
    },

    ('./toolchains/devkitarm/Dockerfile.m4', 'DEVKITARM'): {
        'check': 'docker tag',
        'registry': 'https://registry-1.docker.io',
        'image name': 'devkitpro/devkitarm',
    },

    ('./toolchains/devkitppc/Dockerfile.m4', 'DEVKITPPC'): {
        'check': 'docker tag',
        'registry': 'https://registry-1.docker.io',
        'image name': 'devkitpro/devkitppc',
    },
    ('./toolchains/devkitppc/packages/libgxflux/build.sh', 'GXFLUX'): {
        'check': 'git commit',
        'repository': 'https://repo.or.cz/libgxflux.git',
        'branch': 'master',
    },

    ('./toolchains/devkitswitch/Dockerfile.m4', 'DEVKITA64'): {
        'check': 'docker tag',
        'registry': 'https://registry-1.docker.io',
        'image name': 'devkitpro/devkita64',
    },

    ('./toolchains/iphone/packages/gas-preprocessor/build.sh', 'GAS_PREPROCESSOR'): {
        'check': 'git commit',
        'repository': 'https://github.com/libjpeg-turbo/gas-preprocessor.git',
        'branch': 'master',
    },
    ('./toolchains/iphone/packages/toolchain/build.sh', 'CCTOOLS_PORT'): cctools_port_check,
    ('./toolchains/iphone/packages/toolchain/build.sh', 'LDID'): ldid_check,
    ('./toolchains/iphone/packages/xar/build.sh', 'XAR'): xar_check,

    ('./toolchains/macosx-common/packages/osxcross-clang/build.sh', 'OSXCROSS'): osxcross_check,
    ('./toolchains/macosx-common/packages/osxcross/build.sh', 'OSXCROSS'): osxcross_check,
    ('./toolchains/macosx-common/packages/osxcross/build.sh', 'XAR'): xar_check,
    ('./toolchains/macosx-common/packages/osxcross/build.sh', 'LDID'): ldid_check,
    ('./toolchains/macosx-common/packages/sparkle/build.sh', 'SPARKLE'): {
        'check': 'git tag',
        'repository': 'https://github.com/sparkle-project/Sparkle.git',
        # Only keep vanilla releases
        'pattern': r'^[0-9.]+$',
    },

    ('./toolchains/mxe/Dockerfile.m4', 'MXE'): {
        'check': 'git tag',
        'repository': 'https://github.com/mxe/mxe.git',
        'pattern': '^build-',
    },
    ('./toolchains/mxe/packages/discord-rpc/discord-rpc.mk', ''): discord_rpc_check,
    ('./toolchains/mxe/packages/discord-rpc/rapidjson.mk', ''): {
        'check': 'git tag',
        'repository': 'https://github.com/Tencent/rapidjson.git',
        'prefix': 'v',
        'exclude pattern': r'.*-beta$',
    },
    ('./toolchains/mxe/packages/winsparkle/winsparkle.mk', ''): {
        'check': 'git tag',
        'repository': 'https://github.com/vslavik/winsparkle.git',
        'prefix': 'v',
    },

    # Use same libsdl as Open2x toolchain
    ('./toolchains/open2x/packages/libsdl/build.sh', 'SDL'): 'ignore',

    # OpenPandora packages (except toolchain) are set by (old) firmware
    ('./toolchains/openpandora/packages/alsa-lib/build.sh', 'ALSA_LIB'): 'ignore',
    ('./toolchains/openpandora/packages/curl/build.sh', 'CURL'): 'ignore',
    ('./toolchains/openpandora/packages/faad2/build.sh', 'FAAD2'): 'ignore',
    ('./toolchains/openpandora/packages/flac/build.sh', 'FLAC'): 'ignore',
    ('./toolchains/openpandora/packages/freetype/build.sh', 'FREETYPE'): 'ignore',
    ('./toolchains/openpandora/packages/gnutls/build.sh', 'LIBGPG_ERROR'): 'ignore',
    ('./toolchains/openpandora/packages/gnutls/build.sh', 'LIBGCRYPT'): 'ignore',
    ('./toolchains/openpandora/packages/gnutls/build.sh', 'GNUTLS'): 'ignore',
    ('./toolchains/openpandora/packages/libjpeg/build.sh', 'JPEG'): 'ignore',
    ('./toolchains/openpandora/packages/libogg/build.sh', 'LIBOGG'): 'ignore',
    ('./toolchains/openpandora/packages/libpng/build.sh', 'LIBPNG'): 'ignore',
    ('./toolchains/openpandora/packages/libsdl/build.sh', 'SDL'): 'ignore',
    ('./toolchains/openpandora/packages/libvorbis/build.sh', 'LIBVORBIS'): 'ignore',
    ('./toolchains/openpandora/packages/sdl-net1.2/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/openpandora/packages/tslib/build.sh', 'TSLIB'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'UTIL_MACROS'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'BIGREQSPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'KBPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'INPUTPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'RANDRPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'RENDERPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'XCMISCPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'XEXTPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'XF86BIGFONTPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'XPROTO'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'XTRANS'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBXAU'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBXDMCP'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBX11'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBXEXT'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBXRENDER'): 'ignore',
    ('./toolchains/openpandora/packages/x11/build.sh', 'LIBXRANDR'): 'ignore',
    ('./toolchains/openpandora/packages/zlib/build.sh', 'ZLIB'): 'ignore',
    ('./toolchains/openpandora/packages/toolchain/build.sh', 'CT_NG'): {
        'check': 'git tag',
        'repository': 'https://github.com/crosstool-ng/crosstool-ng.git',
        'prefix': 'crosstool-ng-',
        'exclude pattern': r'.*-rc\d+$',
    },

    ('./toolchains/ps3/packages/sdl_psl1ght/build.sh', 'SDL_PSL1GHT'): {
        'check': 'git commit',
        'repository': 'https://github.com/bgK/sdl_psl1ght.git',
        'branch': 'psl1ght-2.0.3',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'TOOLCHAIN'): {
        'check': 'git commit',
        'repository': 'https://github.com/ps3dev/ps3toolchain.git',
        'branch': 'master',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'PSL1GHT'): {
        'check': 'git commit',
        'repository': 'https://github.com/ps3dev/PSL1GHT.git',
        'branch': 'master',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'PS3LIBRARIES'): {
        'check': 'git commit',
        'repository': 'https://github.com/ps3dev/ps3libraries.git',
        'branch': 'master',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'SDL_PSL1GHT'): {
        'check': 'git commit',
        'repository': 'https://github.com/zeldin/SDL_PSL1GHT.git',
        'branch': 'master',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'SDL_PSL1GHT_LIBS'): {
        'check': 'git commit',
        'repository': 'https://github.com/zeldin/SDL_PSL1GHT_Libs.git',
        'branch': 'master',
    },
    ('./toolchains/ps3/packages/toolchain/build.sh', 'NORSX'): {
        'check': 'git commit',
        'repository': 'https://github.com/wargio/NoRSX.git',
        'branch': 'master',
    },

    ('./toolchains/psp/packages/toolchain/build.sh', 'TOOLCHAIN'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/psptoolchain.git',
        'branch': 'master',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'PSPSDK'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/pspsdk.git',
        'branch': 'master',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'NEWLIB'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/newlib.git',
        'branch': 'newlib-1_20_0-PSP',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'PSPLINKUSB'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/psplinkusb.git',
        'branch': 'master',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'EBOOTSIGNER'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/ebootsigner.git',
        'branch': 'master',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'PSP_PKGCONF'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/psp-pkgconf.git',
        'branch': 'master',
    },
    ('./toolchains/psp/packages/toolchain/build.sh', 'PSPLIBRARIES'): {
        'check': 'git commit',
        'repository': 'https://github.com/pspdev/psplibraries.git',
        'branch': 'master',
    },

    ('./toolchains/raspberrypi/packages/compilers/build.sh', 'DIST'): {
        'check': 'scrape',
        'url': 'http://archive.raspbian.org/raspbian/dists/stable/Release',
        'filter pattern': r'(?m)^Codename: (?P<version>[a-z]+)$',
        'case insensitive': True,
    },
    # It's quite hard to determine which GCC version Raspbian uses and it's tied to DIST
    ('./toolchains/raspberrypi/packages/compilers/build.sh', 'GCC'): 'ignore',

    ('./toolchains/riscos/packages/bindhelp/build.sh', 'BINDHELP'): {
        'check': 'svn commit',
        'repository': 'https://svn.code.sf.net/p/ro-oslib/code/trunk',
    },
    ('./toolchains/riscos/packages/iconv/build.sh', 'LIBICONV'): libiconv_check,
    ('./toolchains/riscos/packages/libsdl1.2/build.sh', 'SDL'): {
        'check': 'hg commit',
        'repository': 'http://hg.libsdl.org/SDL/',
        'branch': 'SDL-1.2',
    },
    ('./toolchains/riscos/packages/tokenize/build.sh', 'TOKENIZE'): {
        'check': 'git commit',
        'repository': 'https://github.com/steve-fryatt/tokenize.git',
        'branch': 'master',
    },
    ('./toolchains/riscos/packages/toolchain/build.sh', 'GCCSDK'): {
        'check': 'svn commit',
        'repository': 'svn://svn.riscos.info/gccsdk/trunk/gcc4/',
    },

    ('./toolchains/vita/packages/toolchain/build.sh', 'VITA'): {
        'check': 'git tag',
        'repository': 'https://github.com/vitasdk/autobuilds.git',
        'prefix': 'master-linux-v',
    },
    ('./toolchains/vita/packages/vita-shader-collection/build.sh', 'VITA_SHDR_COLL'): {
        'check': 'git tag',
        'repository': 'https://github.com/frangarcj/vita-shader-collection.git',
        # Use pattern as prefix would remove it
        'pattern': '^gtu-',
    },
    ('./toolchains/vita/packages/vita2dlib_fbo/build.sh', 'VITA2DLIB'): {
        'check': 'git commit',
        'repository': 'https://github.com/frangarcj/vita2dlib.git',
        'branch': 'fbo',
    },
}
