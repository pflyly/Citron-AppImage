#!/bin/bash -ex

echo "Making Citron for Windows (MSVC)"
if ! echo "$PATH" | grep -q "/c/ProgramData/chocolatey/bin"; then
    export PATH="$PATH:/c/ProgramData/chocolatey/bin"
fi
echo "PATH is: $PATH"

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
EXE_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-Windows-MSVC"

mkdir build
cd build
cmake .. -G Ninja \
    -DCITRON_TESTS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/citron.exe
mkdir deploy
cp -r bin/* deploy/
windeployqt --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"

# Delete un-needed debug symbols 
find deploy -type f -name "*.pdb" -exec rm -f {} +

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.zip"
powershell Compress-Archive "$EXE_NAME" "$ZIP_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
