# This is a template of configuration file for MXE. See
# docs/index.html for more extensive documentations.

# This variable controls the number of compilation processes
# within one package ("intra-package parallelism").
#JOBS := $(JOBS)

# This variable controls where intermediate files are created
# this is necessary when compiling inside a virtualbox shared
# directory. Some commands like strip fail in there with Protocol error
# default is the current directory
#MXE_TMP := /tmp

# This variable controls the targets that will build.
#MXE_TARGETS := $(MXE_TARGET_LIST)
# Build for 32 and 64 bits
MXE_TARGETS := x86_64-w64-mingw32.static i686-w64-mingw32.static

# This variable controls which plugins are in use.
# See plugins/README.md for further information.
#override MXE_PLUGIN_DIRS += plugins/apps plugins/native
override MXE_PLUGIN_DIRS += plugins/windows-xp

# This variable controls the download mirror for SourceForge,
# when it is used. Enabling the value below means auto.
#SOURCEFORGE_MIRROR := downloads.sourceforge.net

# The three lines below makes `make` build these "local
# packages" instead of all packages.
#LOCAL_PKG_LIST := boost curl file flac lzo pthreads vorbis wxwidgets
#.DEFAULT_GOAL  := local-pkg-list
#local-pkg-list: $$(LOCAL_PKG_LIST)

# Don't use ccache
MXE_USE_CCACHE :=

# Don't limit us to 6 jobs when we have plenty CPU
DEFAULT_MAX_JOBS := 10000
