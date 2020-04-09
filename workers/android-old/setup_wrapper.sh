#! /bin/sh

# Create home directory
mkdir -p "${ANDROID_SDK_HOME}"

# Don't do anything after so replace our process
exec "$@"
