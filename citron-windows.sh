#!/bin/sh -ex

git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron

cd ./citron
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"

case "$1" in
    msvc)
        echo "Making Citron for Windows (MSVC)"
        TARGET="Windows-MSVC"
        ;;
    msys2)
        echo "Making Citron for Windows (MSYS2)"
        export ACLOCAL_PATH="/usr/share/aclocal"
        TARGET="Windows-MSYS2"
        ;;
esac
EXE_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-${TARGET}"

mkdir build
cd build
cmake .. -G Ninja \
    -DCITRON_TESTS=OFF \
    -DCITRON_USE_PRECOMPILED_HEADERS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja
ninja bundle
strip -s bundle/*.exe
ccache -s -v

mkdir -p artifacts
mkdir "$EXE_NAME"
EXE_PATH=$(find ./ -type f -name "*.exe" | head -n 1)
mv bundle/* "$REV_NAME"
ZIP_NAME="$REV_NAME.zip"
powershell Compress-Archive "$REV_NAME" "$ZIP_NAME"
mv "$ZIP_NAME" artifacts/
