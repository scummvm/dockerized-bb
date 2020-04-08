#! /bin/sh

unset ANDROID_SDK_ROOT ANDROID_SDK_HOME GRADLE_USER_HOME
ANDROID_SDK_ROOT=/data/bshomes/android/sdk
ANDROID_SDK_HOME=/data/bshomes/android/sdk-home
GRADLE_USER_HOME=/data/bshomes/android/gradle

# Create all directories
mkdir -p "${ANDROID_SDK_ROOT}" "${ANDROID_SDK_HOME}" "${GRADLE_USER_HOME}"

# Copy accepted licenses as we can't accept them during the build process
cp -R "${RO_ANDROID_ROOT}"/master/sdk/licenses "${ANDROID_SDK_ROOT}"/licenses

# Disable gradle build daemon as we kill the container after the build
echo "org.gradle.daemon=false" > "${GRADLE_USER_HOME}"/gradle.properties

# Don't do anything after so replace our process
exec "$@"
