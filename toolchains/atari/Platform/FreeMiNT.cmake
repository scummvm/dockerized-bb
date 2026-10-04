# CMake platform module for FreeMiNT, loaded through CMAKE_SYSTEM_NAME
# FreeMiNT set by atari.platform

# sets UNIX and the standard /usr, /usr/local search prefixes
include(Platform/UnixPaths)

# only static libraries are supported
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
