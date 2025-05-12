#!/bin/bash -ex

echo "Making Citron for Windows (MSYS2)"


if ! git clone 'https://git.citron-emu.org/citron/emu.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pflyly/citron-mirror.git' ./citron
fi

cd ./citron
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
EXE_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-Windows-MSYS2"

sed -i '/std::optional<Network::IPv4Address> GetHostIPv4Address()/,/^}/ s/\binterface\b/netInterface/g' ./src/core/internal_network/network.cpp

mkdir build
cd build
cmake .. -G Ninja \
    -DCITRON_TESTS=OFF \
    -DENABLE_WEB_SERVICE=OFF \
    -DCITRON_USE_BUNDLED_FFMPEG=OFF \
    -DENABLE_LIBUSB=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error -w" \
    -DCMAKE_C_FLAGS="-Wno-error -w"
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/citron.exe
strip -s bin/*.exe
mkdir deploy
cp -r bin/* deploy/
windeployqt --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"

# Delete un-needed debug files 
# find deploy -type f -name "*.pdb" -exec rm -f {} +
# Delete DX components, users should have them already
rm -f deploy/dxcompiler.dll
rm -f deploy/dxil.dll


# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
