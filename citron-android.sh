#!/bin/bash -ex

export NDK_CCACHE=$(which ccache)

git clone --recursive 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    export ANDROID_KEYSTORE_FILE="${GITHUB_WORKSPACE}/ks.jks"
    base64 --decode <<< "${ANDROID_KEYSTORE_B64}" > "${ANDROID_KEYSTORE_FILE}"
fi

cd ./citron
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
APK_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-android-universal"
git submodule update --init --recursive

cd src/android
chmod +x ./gradlew
./gradlew assembleRelease
./gradlew bundleRelease
ccache -s -v

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    rm "${ANDROID_KEYSTORE_FILE}"
fi

mkdir -p artifacts
mv build/bundle/app-release.apk "artifacts/$APK_NAME.apk"
