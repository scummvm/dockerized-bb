import ssl

# saurik's ldid uses outdated TLSv1.0...
TLSv1_CONTEXT = ssl.create_default_context()
try:
    TLSv1_CONTEXT.minimum_version = ssl.TLSVersion.TLSv1
    TLSv1_CONTEXT.set_ciphers("EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:@SECLEVEL=1")
except AttributeError:
    # Too old python won't have TLSVersion, let's hope it will allow TLSv1.0
    pass

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

crosstool_ng_check = {
    'check': 'git tag',
    'repository': 'https://github.com/crosstool-ng/crosstool-ng.git',
    'prefix': 'crosstool-ng-',
    'exclude pattern': r'.*-rc\d+$',
}

# Distributions images checks
debian_check = {
    'check': 'docker tag',
    'registry': 'https://registry-1.docker.io',
    'image name': 'library/debian',
    'architecture': 'amd64',
    'reference': 'bullseye-slim',
    'tag_format': 'bullseye-{0}-slim',
}
raspios_check = {
    'check': 'scrape',
    'url': 'https://downloads.raspberrypi.org/raspios_armhf/os.json',
    'filter pattern': r'(?m)^\s*"version": "(?P<version>[a-z]+)",?$',
    'case insensitive': True,
}
alpine_check = {
    'check': 'docker tag',
    'registry': 'https://registry-1.docker.io',
    'image name': 'library/alpine',
    'architecture': 'amd64',
    'reference': 'latest',
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
    ('./Makefile', 'TREQ'): {
        'check': 'git tag',
        'repository': 'https://github.com/twisted/treq.git',
        'prefix': 'release-',
        'exclude pattern': r'.*(b|rc).*'
    },

    ('./toolchains/m4/debian-toolchain-base.m4', 'DEBIAN'): debian_check,

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
    ('./toolchains/macosx-arm64/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./toolchains/macosx-arm64/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./toolchains/macosx-x86_64/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./toolchains/macosx-x86_64/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./workers/iphone/Dockerfile.m4', 'IPHONE_SDK'): 'ignore',
    ('./workers/macosx-i386/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./workers/macosx-i386/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./workers/macosx-arm64/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./workers/macosx-arm64/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',
    ('./workers/macosx-x86_64/Dockerfile.m4', 'MACOSX_SDK'): 'ignore',
    ('./workers/macosx-x86_64/Dockerfile.m4', 'MACOSX_TARGET'): 'ignore',

    # Caanoo packages (except toolchain) are set by old firmware
    ('./toolchains/caanoo/packages/freetype/build.sh', 'FREETYPE'): 'ignore',
    ('./toolchains/caanoo/packages/libjpeg/build.sh', 'JPEG'): 'ignore',
    ('./toolchains/caanoo/packages/libogg/build.sh', 'LIBOGG'): 'ignore',
    ('./toolchains/caanoo/packages/libpng/build.sh', 'LIBPNG'): 'ignore',
    ('./toolchains/caanoo/packages/libsdl/build.sh', 'SDL'): 'ignore',
    ('./toolchains/caanoo/packages/libvorbisidec/build.sh', 'LIBTREMOR'): 'ignore',
    ('./toolchains/caanoo/packages/sdl-net1.2/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/caanoo/packages/tslib/build.sh', 'TSLIB'): 'ignore',
    ('./toolchains/caanoo/packages/zlib/build.sh', 'ZLIB'): 'ignore',
    ('./toolchains/caanoo/packages/toolchain/build.sh', 'CT_NG'): crosstool_ng_check,

    ('./toolchains/common/packages/discord-rpc/build.sh', 'DISCORD_RPC'): discord_rpc_check,
    ('./toolchains/common/packages/fluidlite/build.sh', 'FLUIDLITE'): {
        'check': 'git commit',
        'repository': 'https://github.com/divideconcept/FluidLite.git',
        'branch': 'master',
    },
    ('./toolchains/common/packages/fluidsynth/build.sh', 'FLUIDSYNTH'): {
        'check': 'git tag',
        'repository': 'https://github.com/FluidSynth/fluidsynth.git',
        'prefix': 'v',
        'exclude pattern': r'.*\.(beta|rc)\d+$'
    },
    ('./toolchains/common/packages/libiconv/build.sh', 'LIBICONV'): libiconv_check,
    ('./toolchains/common/packages/libsdl1.2/build.sh', 'SDL'): {
        'check': 'git commit',
        'repository': 'https://github.com/libsdl-org/SDL-1.2.git',
        'branch': 'main',
    },
    ('./toolchains/common/packages/sdl-net1.2/build.sh', 'SDL_NET'): {
        'check': 'git commit',
        'repository': 'https://github.com/libsdl-org/SDL_net.git',
        'branch': 'SDL-1.2',
    },

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

    ('./toolchains/dreamcast/packages/libronin/build.sh', 'LIBRONIN'): {
        'check': 'git tag',
        'repository': 'https://github.com/sega-dreamcast/libronin.git',
        'prefix': 'ronin_',
    },
    # Dreamcast toolchain is taken from KallistiOS dc-chain and we stick to their versions
    ('./toolchains/dreamcast/packages/toolchain-arm/build.sh', 'BINUTILS'): 'ignore',
    ('./toolchains/dreamcast/packages/toolchain-arm/build.sh', 'GCC'): 'ignore',
    ('./toolchains/dreamcast/packages/toolchain-sh4/build.sh', 'BINUTILS'): 'ignore',
    ('./toolchains/dreamcast/packages/toolchain-sh4/build.sh', 'GCC'): 'ignore',
    ('./toolchains/dreamcast/packages/toolchain-sh4/build.sh', 'NEWLIB'): 'ignore',

    # GCW0 packages (except toolchain) are set by old firmware
    ('./toolchains/gcw0/packages/alsa-lib/build.sh', 'ALSA_LIB'): 'ignore',
    ('./toolchains/gcw0/packages/etna_viv/build.sh', 'ETNA_VIV'): 'ignore',
    ('./toolchains/gcw0/packages/eudev/build.sh', 'EUDEV'): 'ignore',
    ('./toolchains/gcw0/packages/expat/build.sh', 'EXPAT'): 'ignore',
    ('./toolchains/gcw0/packages/flac/build.sh', 'FLAC'): 'ignore',
    ('./toolchains/gcw0/packages/fluidsynth/build.sh', 'FLUIDSYNTH'): 'ignore',
    ('./toolchains/gcw0/packages/freetype/build.sh', 'FREETYPE'): 'ignore',
    ('./toolchains/gcw0/packages/gettext/build.sh', 'GETTEXT'): 'ignore',
    ('./toolchains/gcw0/packages/libdrm/build.sh', 'LIBPTHREAD_STUBS'): 'ignore',
    ('./toolchains/gcw0/packages/libdrm/build.sh', 'LIBDRM'): 'ignore',
    ('./toolchains/gcw0/packages/libffi/build.sh', 'LIBFFI'): 'ignore',
    ('./toolchains/gcw0/packages/libglib2/build.sh', 'GLIB2'): 'ignore',
    ('./toolchains/gcw0/packages/libiconv/build.sh', 'LIBICONV'): 'ignore',
    ('./toolchains/gcw0/packages/libjpeg/build.sh', 'JPEG'): 'ignore',
    ('./toolchains/gcw0/packages/libogg/build.sh', 'LIBOGG'): 'ignore',
    ('./toolchains/gcw0/packages/libpng/build.sh', 'LIBPNG'): 'ignore',
    ('./toolchains/gcw0/packages/libsdl/build.sh', 'SDL'): 'ignore',
    ('./toolchains/gcw0/packages/libsdl2/build.sh', 'SDL'): 'ignore',
    ('./toolchains/gcw0/packages/libsndfile/build.sh', 'LIBSNDFILE'): 'ignore',
    ('./toolchains/gcw0/packages/libtheora/build.sh', 'LIBTHEORA'): 'ignore',
    ('./toolchains/gcw0/packages/libvorbisidec/build.sh', 'LIBTREMOR'): 'ignore',
    ('./toolchains/gcw0/packages/mesa3d-etna_viv/build.sh', 'MESA3D_ETNA_VIV'): 'ignore',
    ('./toolchains/gcw0/packages/sdl-net1.2/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/gcw0/packages/sdl2-net/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/gcw0/packages/zlib/build.sh', 'ZLIB'): 'ignore',
    ('./toolchains/gcw0/packages/toolchain/build.sh', 'CT_NG'): crosstool_ng_check,

    ('./toolchains/iphone/packages/toolchain/build.sh', 'CCTOOLS_PORT'): cctools_port_check,
    ('./toolchains/iphone/packages/toolchain/build.sh', 'LDID'): {
        'check': 'git commit',
        'repository': 'https://github.com/tpoechtrager/ldid.git',
        'branch': 'master',
    },
    ('./toolchains/iphone/packages/xar/build.sh', 'XAR'): xar_check,

    ('./toolchains/macosx-common/packages/osxcross-clang/build.sh', 'OSXCROSS'): osxcross_check,
    ('./toolchains/macosx-common/packages/osxcross/build.sh', 'OSXCROSS'): osxcross_check,
    ('./toolchains/macosx-common/packages/osxcross/build.sh', 'XAR'): xar_check,
    ('./toolchains/macosx-common/packages/ldid/build.sh', 'LDID'): {
        # For MacOSX we need upstream ldid with latest MacOS support
        'check': 'git tag',
        'repository': 'https://git.saurik.com/ldid.git',
        'context': TLSv1_CONTEXT,
        'prefix': 'v',
    },
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

    ('./toolchains/n64/packages/libvorbisidec/build.sh', 'LIBTREMOR'): {
        'check': 'git commit',
        'repository': 'https://gitlab.xiph.org/xiph/tremor.git',
        'branch': 'lowmem',
    },
    ('./toolchains/n64/packages/toolchain-mips64/build.sh', 'BINUTILS'): 'ignore',
    ('./toolchains/n64/packages/toolchain-mips64/build.sh', 'GCC'): 'ignore',
    ('./toolchains/n64/packages/toolchain-mips64/build.sh', 'NEWLIB'): 'ignore',
    ('./toolchains/n64/packages/ucon64/build.sh', 'UCON64'): {
        'check': 'svn tag',
        'repository': 'https://svn.code.sf.net/p/ucon64/svn/tags/',
        'prefix': 'ucon64-',
    },

    # OpenDingux packages (except toolchain) are set by (old) firmware
    ('./toolchains/opendingux/packages/alsa-lib/build.sh', 'ALSA_LIB'): 'ignore',
    ('./toolchains/opendingux/packages/flac/build.sh', 'FLAC'): 'ignore',
    ('./toolchains/opendingux/packages/freetype/build.sh', 'FREETYPE'): 'ignore',
    ('./toolchains/opendingux/packages/libiconv/build.sh', 'LIBICONV'): 'ignore',
    ('./toolchains/opendingux/packages/libjpeg/build.sh', 'JPEG'): 'ignore',
    ('./toolchains/opendingux/packages/libmad/build.sh', 'LIBMAD'): 'ignore',
    ('./toolchains/opendingux/packages/libogg/build.sh', 'LIBOGG'): 'ignore',
    ('./toolchains/opendingux/packages/libpng/build.sh', 'LIBPNG'): 'ignore',
    ('./toolchains/opendingux/packages/libsdl/build.sh', 'SDL'): 'ignore',
    ('./toolchains/opendingux/packages/libtheora/build.sh', 'LIBTHEORA'): 'ignore',
    ('./toolchains/opendingux/packages/libvorbisidec/build.sh', 'LIBTREMOR'): 'ignore',
    ('./toolchains/opendingux/packages/sdl-net1.2/build.sh', 'SDL_NET'): 'ignore',
    ('./toolchains/opendingux/packages/zlib/build.sh', 'ZLIB'): 'ignore',
    ('./toolchains/opendingux/packages/toolchain/build.sh', 'CT_NG'): crosstool_ng_check,

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
    ('./toolchains/openpandora/packages/toolchain/build.sh', 'CT_NG'): crosstool_ng_check,

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

    ('./toolchains/raspberrypi/packages/compilers/build.sh', 'DIST'): raspios_check,
    ('./toolchains/raspberrypi/packages/sysroot/build.sh', 'RASPBIAN'): raspios_check,
    # It's quite hard to determine which GCC version Raspbian uses and it's tied to DIST
    ('./toolchains/raspberrypi/packages/compilers/build.sh', 'GCC'): 'ignore',

    ('./toolchains/riscos/packages/bindhelp/build.sh', 'BINDHELP'): {
        'check': 'svn commit',
        'repository': 'https://svn.code.sf.net/p/ro-oslib/code/trunk',
    },
    ('./toolchains/riscos/packages/iconv/build.sh', 'LIBICONV'): libiconv_check,
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

    ('./toolchains/windows-9x/packages/pe-util/build.sh', 'PE_UTIL'): {
        'check': 'git commit',
        'repository': 'https://github.com/gsauthof/pe-util.git',
        'branch': 'master',
    },
    ('./toolchains/windows-9x/packages/toolchain/build.sh', 'BINUTILS'): 'ignore',
    ('./toolchains/windows-9x/packages/toolchain/build.sh', 'GCC'): 'ignore',
    ('./toolchains/windows-9x/packages/toolchain/build.sh', 'MINGWRT'): 'ignore',
    ('./toolchains/windows-9x/packages/toolchain/build.sh', 'W32API'): 'ignore',

    ('./workers/fetcher/Dockerfile.m4', 'ALPINE'): alpine_check,
    ('./workers/m4/debian-builder-base.m4', 'DEBIAN'): debian_check,
}
