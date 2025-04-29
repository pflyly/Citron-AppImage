#!/bin/bash -ex

git clone 'https://git.citron-emu.org/citron/emu.git' ./citron

cd ./citron
git submodule update --init --recursive

# workaround for android
sed -i 's/"boost-process"[[:space:]]*,*/{"name": "boost-process", "platform": "!android"},/' vcpkg.json
find src -type f -name 'build.gradle.kts' -exec sed -i 's/"4\.0\.1"/"3.31.6"/g' {} +

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
APK_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-android-universal"

cd src/android
chmod +x ./gradlew
./gradlew assembleRelease --console=plain --info -Dorg.gradle.caching=true

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: APK not found in expected directory."
    exit 1
fi
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"
